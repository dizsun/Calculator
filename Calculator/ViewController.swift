//
//  ViewController.swift
//  Calculator
//
//  Created by SunDiz on 16/3/14.
//  Copyright © 2016 SunDiz. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    //MARK: 显示屏
    @IBOutlet weak var display: UILabel!
    
    fileprivate var displayValue:[String] = []{
        didSet{
            display?.text! = ""
            for eachStr in displayValue {
                display.text! += eachStr
            }
            if displayValue.isEmpty {
                display.text! = "0"
            }
        }
    }
    //在输入或输出模式下转换文本显示形式
    //若是正在输入则截取后面部分
    //否则截取前面部分
    fileprivate var isInputing = false {
        didSet{
            if isInputing{
                display.lineBreakMode = NSLineBreakMode.byTruncatingHead
            }
            else{
                display.lineBreakMode = NSLineBreakMode.byTruncatingTail
            }
        }
    }

    //MARK: 逻辑控制
    fileprivate var brain = CalculatorBrain()
    /*
    clickTimes属性与下面的dealingComplex函数专为ios脑残的单击/双击事件定制，可区分他们
    */
    fileprivate var clickTimes = 0 {
        didSet{
            if clickTimes == 2 {
                brain.popOperand()
                displayValue.removeLast()
                clickTimes = 0
            }
            
        }
    }
    fileprivate func dealingComplexBtn(_ text:String){
        brain.pushOperand(text)
        displayValue.append(text)
        clickTimes += 1
        clickTimes = 0
    }
    
    @IBAction func onNumberOrOperandClicked(_ sender: UIButton) {
        let text = sender.currentTitle!
        isInputing = true
        switch text {
            case "^/tan":
                dealingComplexBtn("^")
            case "log/sin":
                dealingComplexBtn("log")
            case "ln/cos":
                dealingComplexBtn("ln")
            case "./e":
                dealingComplexBtn(".")
            case "0/pi":
                dealingComplexBtn("0")
            default:
                brain.pushOperand(text)
                displayValue.append(text)
        }
    }

    @IBAction func onOperandDoubleClicked(_ sender: UIButton) {
        let text = sender.currentTitle!
        clickTimes = 1
        brain.popOperand()
        displayValue.removeLast()
        isInputing = true
        switch text {
        case "^/tan":
            brain.pushOperand("tan")
            displayValue.append("tan")
        case "log/sin":
            brain.pushOperand("sin")
            displayValue.append("sin")
        case "ln/cos":
            brain.pushOperand("cos")
            displayValue.append("cos")
        case "./e":
            brain.pushOperand("e")
            displayValue.append("e")
        case "0/pi":
            brain.pushOperand("pi")
            displayValue.append("pi")
        default:
            break
        }
    }
    
    @IBAction func onEqualClicked() {
        isInputing = false
        if let value = brain.evaluate(){
            displayValue.removeAll()
            displayValue.append("\(value)")
        }
        else{
            displayValue.removeAll()
            displayValue.append("输入格式错误")
        }
    }

    @IBAction func onDelClicked() {
        isInputing = true
        brain.popOperand()
        if !displayValue.isEmpty {
            displayValue.removeLast()
        }
    }
    
    @IBAction func onCEClicked() {
        isInputing = true
        brain.clearOpSatck()
        displayValue.removeAll()
    }

    @IBAction func ddddd(_ sender: UIButton) {
        print("???????")
    }
    
}

