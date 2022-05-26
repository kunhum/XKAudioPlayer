//
//  ViewController.swift
//  XKAudioPlayer
//
//  Created by kenneth on 05/23/2022.
//  Copyright (c) 2022 kenneth. All rights reserved.
//

import UIKit
import XKAudioPlayer
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
    let mp31 = "http://downsc.chinaz.net/Files/DownLoad/sound1/201906/11582.mp3"
    let mp32 = "http://downsc.chinaz.net/files/download/sound1/201206/1638.mp3"
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    let player = XKAudioPlayer()
    
    var tag: Int = 0
    
    let disposeBag = DisposeBag()
    var reuseBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        player.indexSubject.skip(1).bind { [weak self] index in
            switch index {
            case 1:
                self?.imageView.image = UIImage(named: "hj2")
            default:
                self?.imageView.image = UIImage(named: "hj1")
            }
            self?.infoLabel.text = "第\(index+1)个"
        }.disposed(by: disposeBag)
        
        player.statusSubject.skip(1).bind { [weak self] status in
            switch status {
            case .unknow:
                break
            case .playing:
                self?.statusLabel.text = "播放中"
                self?.start()
            case .pause:
                self?.statusLabel.text = "暂停"
            case .stop:
                self?.statusLabel.text = "已停止"
                self?.stop()
            case .loading:
                self?.statusLabel.text = "加载中"
            }
        }.disposed(by: disposeBag)
        
        player.progressSubject.skip(1).bind { [weak self] item in
            self?.progressView.progress = Float(item?.progress ?? 0.0)
        }.disposed(by: disposeBag)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let path1 = Bundle.main.path(forResource: "1.mp3", ofType: nil), let path2 = Bundle.main.path(forResource: "2.mp3", ofType: nil) else { return }
        
        switch tag {
        case 0:
            player.playLocal(paths: [path1, path2])
        case 1:
            player.appendLocal(path: path1)
        case 2:
            player.pause()
        case 3:
            player.resume()
        case 4:
            player.stop()
        default:
            break
        }
        
        tag += 1
       
        
    }
    
    func start() {
        reuseBag = DisposeBag()
        var angle = 0.0
        Observable<Int>
            .interval(RxTimeInterval.microseconds(1), scheduler: ConcurrentMainScheduler.instance)
            .bind { [weak self] interval in
                guard let self = self else { return }
                
                let r = Double.pi * 2.0 / 360.0 / 1000.0
                angle += 2.0*r
                self.imageView.transform = CGAffineTransform(rotationAngle: angle)
                
            }.disposed(by: reuseBag)
    }
    
    func stop() {
        reuseBag = DisposeBag()
        imageView.transform = CGAffineTransform.identity
    }
}

