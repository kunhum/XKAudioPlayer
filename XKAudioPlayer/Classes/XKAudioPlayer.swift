//
//  XKAudioPlayer.swift
//  XKAudioPlayer
//
//  Created by kenneth on 2022/5/23.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

// swiftlint:disable trailing_whitespace
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length
@objcMembers
public class XKAudioPlayer: NSObject {
    
    public static let shared = XKAudioPlayer()
    
    public enum Status: Int {
        case unknow
        case stop
        case playing
        case pause
        case loading
    }
    
    public class Item {
        public var item: AVPlayerItem?
        /// 建议floor
        public var second: Double = 0.0
        public var duration: Double = 0.0
        public var progress: Double = 0.0
        public var path: String = ""
    }
    
    public let indexSubject = BehaviorRelay<Int>(value: 0)
    public let statusSubject = BehaviorRelay<Status>(value: .unknow)
    public let progressSubject = PublishSubject<Item?>()
    public var currentItem: Item? {
        return fetchCurrentItem()
    }
    
    lazy var player: AVQueuePlayer = {
        let player = AVQueuePlayer()
        observerData()
        return player
    }() {
        didSet {
            observerData()
        }
    }
    var observerBag = DisposeBag()
    var itemStatusBag = DisposeBag()
    var items: [Item] = []
}

public extension XKAudioPlayer {
    /// 播放多个音频，会重置播放器，推荐一开始调用此方法播放，之后可调用append
    func play(paths: [String]) {
        guard paths.isEmpty == false else {
            printMessage()
            return
        }
        var urls = [URL]()
        paths.forEach { path in
            guard let url = URL(string: path) else { return }
            urls.append(url)
        }
        internal_play(urls: urls)
    }
    
    func append(path: String) {
        guard path.isEmpty == false else {
            printMessage()
            return
        }
        guard let url = URL(string: path) else {
            printMessage()
            return
        }
        internal_append(url: url)
    }
    
    func playLocal(paths: [String]) {
        
        guard paths.isEmpty == false else {
            printMessage()
            return
        }
        var urls = [URL]()
        paths.forEach { path in
            let url = URL(fileURLWithPath: path)
            urls.append(url)
        }
        internal_play(urls: urls)
    }
    
    func appendLocal(path: String) {
        
        guard path.isEmpty == false else {
            printMessage()
            return
        }
        let url = URL(fileURLWithPath: path)
        internal_append(url: url)
    }
    
    func reset() {
        items.removeAll()
        player = AVQueuePlayer()
    }
    
    func pause() {
        player.pause()
    }
    
    func stop() {
        reset()
        statusSubject.accept(.stop)
    }
    
    func resume() {
        player.play()
    }
}

fileprivate extension XKAudioPlayer {
    func internal_play(urls: [URL]) {
        
        guard urls.isEmpty == false else {
            printMessage()
            return
        }
        
        let items = urls.map { url -> AVPlayerItem in
            return AVPlayerItem(url: url)
        }
        self.items = items.map({ item -> Item in
            let obj = Item()
            obj.item = item
            if let asset = item.asset as? AVURLAsset {
                obj.path = asset.url.absoluteString
            }
            return obj
        })
        player = AVQueuePlayer(items: items)
        player.play()
    }
    func internal_append(url: URL) {
        
//        if player.items().isEmpty {
//            play(paths: [url.absoluteString])
//            return
//        }
        let item = AVPlayerItem(url: url)
        guard player.canInsert(item, after: player.items().last) else { return }
        let obj = Item()
        obj.item = item
        items.append(obj)
        player.insert(item, after: player.items().last)
    }
    
    func printMessage(_ message: String = "请检查播放地址是否正确") {
        debugPrint(message)
    }
    func observerData() {
        observerBag = DisposeBag()
        player.rx.observe(AVPlayerItem.Status.self, "status").bind { status in
            switch status {
            case .unknown:
                break
            case .readyToPlay:// 播放器开始播放
                break
            case .failed:
                break
            case .none:
                break
            case .some:
                break
            }
        }.disposed(by: observerBag)
        
        player.rx.observe(AVPlayerItem.self, "currentItem").bind { [weak self] curItem in
            self?.playingItemDidChange(item: curItem)
        }.disposed(by: observerBag)
        
        player
            .rx
            .observe(AVPlayer.TimeControlStatus.self, "timeControlStatus").bind { [weak self] status in
            switch status {
            case .paused:
                self?.statusSubject.accept(.pause)
            case .playing:
                self?.statusSubject.accept(.playing)
            case .waitingToPlayAtSpecifiedRate:
                if self?.player.currentItem != self?.player.items().last {
                    self?.statusSubject.accept(.loading)
                }
            default:
                break
            }
        }.disposed(by: observerBag)
        
        player
            .addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1),
                                     queue: .global(qos: .background)
            ) { [weak self] cmTime in
                let second = cmTime.seconds
                guard let items = self?.items else { return }
                guard let curItem = self?.player.currentItem else { return }
                guard let item = items.first(where: { item in
                    item.item == curItem
                }) else { return }
                item.second = second
                item.duration = curItem.duration.seconds
                item.progress = second / curItem.duration.seconds
                DispatchQueue.main.async { [weak self] in
                    self?.progressSubject.onNext(item)
                }
                
        }
        
        NotificationCenter.default
            .rx
            .notification(NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
            .bind { [weak self] notification in
                guard let item = notification.object as? AVPlayerItem, item == self?.player.currentItem else { return }
                self?.statusSubject.accept(.stop)
            }
            .disposed(by: observerBag)
        
    }
    func playingItemDidChange(item: AVPlayerItem?) {
        itemStatusBag = DisposeBag()
        guard let curItem = player.currentItem else { return }
        guard let index = items.firstIndex(where: { item in
            return item.item == curItem
        }) else { return }
        indexSubject.accept(index)
    }
    
    func fetchCurrentItem() -> Item? {
        guard let curItem = player.currentItem else { return nil }
        return items.first { item in
            return item.item == curItem
        }
    }
}
