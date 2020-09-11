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
    
    var starWidth: CGFloat = 25 {
        didSet {
            starWidth = max(0, starWidth)
            starHeight = starWidth * 0.95
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
       
    private var starHeight: CGFloat = 23.75
    private (set) var value: Int = 0
    private var stars: [StarLayer] = []
    private var oldFrame: CGRect
    private let generator = UISelectionFeedbackGenerator()
    
    override init(frame: CGRect) {
        oldFrame = frame
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        oldFrame = .zero
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
        
        if oldFrame.size != frame.size {
            drawStars()
            oldFrame = frame
        }
    }
    
    private func createStars() {
        stars = (0..<maximumValue).map { _ in StarLayer() }
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        stars.forEach { layer.addSublayer($0) }
    }
    
    private func drawStars() {
        let allStarsWidth: CGFloat = starWidth * CGFloat(maximumValue)
        let allInsetsWidth: CGFloat = inset * CGFloat(maximumValue - 1)
        let heightIndent: CGFloat = (self.bounds.size.height - starHeight) / 2
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
        
        stars.enumerated().forEach { (number, star) in
            let position: CGFloat = widthIndent + (starWidth + inset) * CGFloat(number)
            star.updateBounds(CGRect(x: position, y: heightIndent, width: starWidth, height: starHeight))
        }
    }
    
    public func setValue(_ newValue: Int) {
        value = min(maximumValue, max(0, newValue))
        
        stars.enumerated().forEach { (number, star) in
            star.isSelected = number < value
        }
    }
    
    @objc private func touchedDown(control: MyCustomControl, withEvent event: UIEvent) {
        guard let touch = event.touches(for: control)?.first else { return }
        let location = touch.location(in: control)
        guard let layerNumber = getPositionExpanded(inside: location) else { return }
            
        let newValue = layerNumber + 1
        if newValue != value {
            setValue(newValue)
            sendActions(for: .valueChanged)
        }
    }
    
    @objc private func dragInside(control: MyCustomControl, withEvent event: UIEvent) {
        guard let touch = event.touches(for: control)?.first else { return }
        let location = touch.location(in: control)
        guard let layerNumber = getPosition(inside: location) else { return }
            
        let newValue = layerNumber + 1
        if newValue != value {
            setValue(newValue)
            generator.selectionChanged()
            sendActions(for: .valueChanged)
        }
    }
    
    @objc private func dragOutside(control: MyCustomControl, withEvent event: UIEvent) {
        guard let touch = event.touches(for: control)?.first else { return }
        let location = touch.location(in: control)
        guard let layerNumber = getPosition(outside: location) else { return }
            
        let newValue = layerNumber + 1
        if newValue != value {
            setValue(newValue)
            generator.selectionChanged()
            sendActions(for: .valueChanged)
        }
    }
    
    private func getPosition(inside location: CGPoint) -> Int? {
        for (number, star) in stars.enumerated() {
            if star.bounds.contains(location) {
                return number
            }
        }
        
        return nil
    }
    
    private func getPosition(outside location: CGPoint) -> Int? {
        for (number, star) in stars.enumerated() {
            if (location.x > star.bounds.minX) && (location.x < star.bounds.maxX) {
                return number
            }
        }
        
        return nil
    }
    
    private func getPositionExpanded(inside location: CGPoint) -> Int? {
        for (number, star) in stars.enumerated() {
            let expandedBounds = star.bounds.insetBy(dx: -inset / 2, dy: -inset / 2)
            if expandedBounds.contains(location) {
                return number
            }
        }
        
        return nil
    }
}

private class StarLayer: CAShapeLayer {
    
    // Цвета звезды, желтый и серый. В фигме заданы в hex
    private static let selectedStarColor = UIColor(red: 1.000, green: 0.796, blue: 0.078, alpha: 1)
    private static let unselectedStarColor = UIColor(red: 0.855, green: 0.855, blue: 0.855, alpha: 1)
    
    var color: UIColor = StarLayer.unselectedStarColor {
        didSet {
            self.fillColor = color.cgColor
            self.strokeColor = color.cgColor
        }
    }
    
    var isSelected: Bool = false {
        didSet {
            color = isSelected ? StarLayer.selectedStarColor : StarLayer.unselectedStarColor
        }
    }
        
    func updateBounds(_ bounds: CGRect) {
        self.bounds = bounds
        self.position = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        
        let startX = Double(self.bounds.midX)
        // Середина звезды по высоте находится не в середине прямоугольника, а чуть ниже
        let startY = Double(self.bounds.midY * 1.05)
        // Добавляется stroke толщиной в 10% от размера звезды
        self.lineWidth = self.bounds.size.width * 0.1
        // Размер звезды уменьшается на 10% так как добавляется stroke
        let width = self.bounds.size.width * 0.9
        /* Радиус описанной окружности находится по формуле
         https://ru.wikipedia.org/wiki/Правильный_пятиугольник */
        let radius = Double(width / 1.902)
                        
        var points: Array<CGPoint> = []
        
        // Пять точек звезды в соответствии с формулой
        for k in 0...4 {
            let value: Double = ((2 * .pi * Double(k)) / 5) + (.pi / 2)
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
        
        self.path = path.cgPath
    }
    
    private func commonInit() {
        self.fillColor = color.cgColor
        self.strokeColor = color.cgColor
        self.lineJoin = .round
    }
    
    override init() {
        super.init()
        commonInit()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
}


