//
//  MyCustomControl.swift
//  uicontroltest
//
//  Created by Евгений Испольнов on 20.08.2020.
//  Copyright © 2020 Евгений Испольнов. All rights reserved.
//

import UIKit

class MyCustomControl: UIControl {

    var maximumValue: Int = 5 {
        didSet {
            maximumValue = min(10, max(0, maximumValue))
            createStars()
            drawStars()
        }
    }
    
    var starHeight: CGFloat = 25 {
        didSet {
            starHeight = max(0, starHeight)
            drawStars()
        }
    }
    
    var starWidth: CGFloat = 27.25 {
        didSet {
            starWidth = max(0, starWidth)
            drawStars()
        }
    }
    
    var inset: CGFloat = 10 {
        didSet {
            inset = max(0, inset)
            drawStars()
        }
    }
    
    override var contentHorizontalAlignment: UIControl.ContentHorizontalAlignment {
        didSet {
            drawStars()
        }
    }
        
    private (set) var value: Int = 0
    private var stars: Array<Star> = []
    private var oldFrame: CGRect?
    private let generator = UISelectionFeedbackGenerator()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        createStars()
        drawStars()
        self.addTarget(self, action: #selector(touchedDown), for: .touchDown)
        self.addTarget(self, action: #selector(dragInside), for: .touchDragInside)
        self.addTarget(self, action: #selector(dragOutside), for: .touchDragOutside)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if oldFrame != nil {
            if oldFrame?.size != frame.size {
                drawStars()
            }
        }
        
        oldFrame = frame
    }
    
    private func createStars() {
        stars = []
        layer.sublayers?.removeAll()
        
        for _ in 0..<maximumValue {
            let star = Star()
            layer.addSublayer(star.starLayer)
            stars.append(star)
        }
    }
    
    private func drawStars() {
        let allStarsWidth = starWidth * CGFloat(maximumValue)
        let allInsetsWidth = inset * CGFloat(maximumValue - 1)
        let heightIndent = (self.bounds.size.height - starHeight) / 2
        let widthIndent: CGFloat
        
        switch contentHorizontalAlignment {
        case .center, .fill:
            widthIndent = (self.bounds.size.width - allStarsWidth - allInsetsWidth) / 2
        case .left, .leading:
            widthIndent = 0
        case .right, .trailing:
            widthIndent = (self.bounds.size.width - allStarsWidth - allInsetsWidth)
        @unknown default:
            widthIndent = 0
        }
        
        for number in 0..<maximumValue {
            stars[number].updateBounds(CGRect(x: widthIndent + (starWidth + inset) * CGFloat(number), y: heightIndent, width: starWidth, height: starHeight))
        }
    }
    
    public func setValue(_ newValue: Int) {
        value = min(maximumValue, max(0, newValue))
        
        for number in 0..<maximumValue {
            stars[number].isSelected = number < value ? true : false
        }
    }
    
    @objc private func touchedDown(control: MyCustomControl, withEvent event: UIEvent) {
        if let touch = event.touches(for: control)?.first {
            let location = touch.location(in: control)
            let layerNumber = checkCollision(location: location)
            
            if layerNumber != nil {
                let newValue = layerNumber! + 1
                if newValue != value {
                    setValue(newValue)
                    sendActions(for: .valueChanged)
                }
            }
        }
    }
    
    @objc private func dragInside(control: MyCustomControl, withEvent event: UIEvent) {
        if let touch = event.touches(for: control)?.first {
            let location = touch.location(in: control)
            let layerNumber = checkCollision(location: location)
            
            if layerNumber != nil {
                let newValue = layerNumber! + 1
                if newValue != value {
                    setValue(newValue)
                    generator.selectionChanged()
                    sendActions(for: .valueChanged)
                }
            }
        }
    }
    
    @objc private func dragOutside(control: MyCustomControl, withEvent event: UIEvent) {
        if let touch = event.touches(for: control)?.first {
            let location = touch.location(in: control)
            var layerNumber: Int?
            
            for number in 0..<maximumValue {
                if (location.x > stars[number].starLayer.bounds.minX) && (location.x < stars[number].starLayer.bounds.maxX) {
                    layerNumber = number
                }
            }
            
            if layerNumber != nil {
                let newValue = layerNumber! + 1
                if newValue != value {
                    setValue(newValue)
                    generator.selectionChanged()
                    sendActions(for: .valueChanged)
                }
            }
        }
    }
    
    private func checkCollision(location: CGPoint) -> Int? {
        var result: Int?
        
        for number in 0..<maximumValue {
            if stars[number].starLayer.bounds.contains(location) {
                result = number
            }
        }
        
        return result
    }
}

private class Star {
    
    var color: UIColor = Constants.unselectedStarColor {
        didSet {
            starLayer.fillColor = color.cgColor
            starLayer.strokeColor = color.cgColor
        }
    }
    
    var isSelected: Bool = false {
        didSet {
            color = isSelected ? Constants.selectedStarColor : Constants.unselectedStarColor
        }
    }
    
    let starLayer = CAShapeLayer()
    
    func updateBounds(_ bounds: CGRect) {
        starLayer.bounds = bounds
        starLayer.position = CGPoint(x: starLayer.bounds.midX, y: starLayer.bounds.midY)
        
        let startX = Double(starLayer.bounds.midX)
        // Середина звезды по высоте находится не в середине прямоугольника, а чуть ниже
        let startY = Double(starLayer.bounds.midY * 1.05)
        starLayer.lineWidth = starLayer.bounds.size.width * 0.1
        // Размер звезды уменьшается на 10% так как добавляется stroke
        let width = starLayer.bounds.size.width * 0.9
        let radius = Double(width / 1.902)
                        
        var points: Array<CGPoint> = []
        
        // Пять точек звезды в соответствии с формулой
        for k in 0...4 {
            let value: Double = ((2 * 3.14 * Double(k)) / 5) + (3.14 / 2)
            points.append(CGPoint(x: startX + radius * -cos(value), y: startY + radius * -sin(value)))
        }
            
        // Звезда отрисовывается линиями по точкам, через одну
        let path = UIBezierPath()
        path.move(to: points[0])
        path.addLine(to: points[2])
        path.addLine(to: points[4])
        path.addLine(to: points[1])
        path.addLine(to: points[3])
        path.addLine(to: points[0])
        path.close()
        
        starLayer.path = path.cgPath
    }
    
    init() {
        starLayer.fillColor = color.cgColor
        starLayer.strokeColor = color.cgColor
        starLayer.lineJoin = .round        
    }
}

private enum Constants {
    static let selectedStarColor = UIColor(red: 1.000, green: 0.796, blue: 0.078, alpha: 1)
    static let unselectedStarColor = UIColor(red: 0.855, green: 0.855, blue: 0.855, alpha: 1)
}

