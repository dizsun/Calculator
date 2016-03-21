//
//  ViewController.swift
//  Calculator
//
//  Created by SunDiz on 16/3/14.
//  Copyright © 2016 SunDiz. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    //显示屏
    @IBOutlet weak var display: UILabel!
    
    //逻辑控制
    var brain = CalculatorBrain()
    //用户是否正在输入数字
    var userIsInTheMiddleOfTypingANumber: Bool = false
    
    //输入数字
    @IBAction func appendDigit(sender: UIButton) {
        if let digit = sender.currentTitle{
            if let text = display.text{
                if userIsInTheMiddleOfTypingANumber{
                    display.text = text + digit
                }
                else{
                    display.text = digit
                    userIsInTheMiddleOfTypingANumber = true
                }
            }
        }
    }
    
    //按下运算符按钮
    @IBAction func operate(sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber {
            enter()
        }
        guard let operation = sender.currentTitle else{
            return
        }
        displayValue = brain.performOperation(operation)
        
    }
    
    //按下确认按钮
    @IBAction func enter() {
        userIsInTheMiddleOfTypingANumber = false
        displayValue = brain.pushOperand(displayValue)
    }
    
    //管理显示屏数字
    var displayValue: Double?{
        get{
            guard let value = display.text else{
                return 0
            }
            guard let digits = Double.init(value) else{
                return 0
            }
            return digits
        }
        set{
            if let v = newValue{
                display.text = "\(v)"
            }
            else{
                display.text = "Error!"
            }
            userIsInTheMiddleOfTypingANumber = false
        }
    }
    
}

