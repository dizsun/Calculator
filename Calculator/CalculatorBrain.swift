//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by SunDiz on 16/3/17.
//  Copyright © 2016年 SunDiz. All rights reserved.
//

import Foundation

/*
     计算器的逻辑控制模块
*/
class CalculatorBrain {
    //MARK: 内置数据
    //计算器的输入有三类：数字、一元运算符、二元运算符
    fileprivate enum Operation: CustomStringConvertible {
        case operand(Double)    //运算数字
        case unaryOperator(String,(Double)->Double)  //一元运算符
        case binaryOperator(String,(Double,Double)->Double)    //二元运算符
        case dot
        case parenthese(Bool)//括号，如果Parenthese的值是true则为)否则为(
        case pi
        case e
        //Op的toString方法
        var description:String{
            get{
                switch self{
                case .operand(let operand):
                    return "\(operand)"
                case .unaryOperator(let operation, _):
                    return "\(operation)"
                case .binaryOperator(let operation, _):
                    return "\(operation)"
                case .dot:
                    return "."
                case .parenthese(let direction):
                    if direction {
                        return ")"
                    }
                    else{
                        return "("
                    }
                case .pi:
                    return "pi"
                case .e:
                    return "e"
                }
            }
        }
        //运算符的比较，+，-运算优先级最小为0，*，/为1，^为2，单目运算符为3
        func compareTo(_ other:Operation) -> Int {
            let priority = [ "+":0, "−":0, "×":1, "÷":1, "^":2, "√":3, "log":3, "ln":3, "sin":3, "cos":3, "tan":3 ]
            if priority.keys.contains(self.description)
                && priority.keys.contains(other.description) {
                return priority[self.description]! - priority[other.description]!
            }
            return 0
        }
    }
    //盛放输入内容的栈
    fileprivate var preStack = [Operation]()
    //所有会用到的运算符集合
    fileprivate var knownOps = [String:Operation]()
    
    init(){
        knownOps["+"] = Operation.binaryOperator("+", +)
        knownOps["−"] = Operation.binaryOperator("−", -)
        knownOps["×"] = Operation.binaryOperator("×", *)
        knownOps["÷"] = Operation.binaryOperator("÷", /)
        knownOps["^"] = Operation.binaryOperator("^", pow)
        knownOps["√"] = Operation.unaryOperator("√", sqrt)
        knownOps["log"] = Operation.unaryOperator("log", log2)
        knownOps["ln"] = Operation.unaryOperator("ln", log)
        knownOps["sin"] = Operation.unaryOperator("sin", sin)
        knownOps["cos"] = Operation.unaryOperator("cos", cos)
        knownOps["tan"] = Operation.unaryOperator("tan", tan)
        knownOps["("] = Operation.parenthese(false)
        knownOps[")"] = Operation.parenthese(true)
        knownOps["."] = Operation.dot
        knownOps["e"] = Operation.e
        knownOps["pi"] = Operation.pi
    }
    //MARK: 接口函数
    //计算算式值
    func evaluate() -> Double?{
        if !parseFormula() {
            return nil
        }
        //        print(preStack)
        preToIn()
        //        print(inStack)
        return Double(calculateIn()!)
    }
    //将运算数字或运算符压入栈中
    func pushOperand(_ operand: String){
        if knownOps.keys.contains(operand) {
            preStack.append(knownOps[operand]!)
        }
        else{
            preStack.append(Operation.operand(Double(operand)!))
        }
    }

    //将输入的数字或运算符删除一个
    func popOperand(){
        if preStack.count > 0 {
            preStack.popLast()
        }
    }
    //将输入的内容清零
    func clearOpSatck(){
        preStack.removeAll()
    }
    //MARK: 运算逻辑
    //中缀表达式
    fileprivate var inStack = [Operation]()
    //算式解析，将数字拼在一起，将E与PI替换成数字
    fileprivate func parseFormula() -> Bool {
        //首先判断括号是否一一匹配
        var parentsis = 0
        for op in preStack {
            switch op {
            case .parenthese(let direction):
                if direction {
                    parentsis=parentsis-1
                }
                else{
                    parentsis=parentsis+1
                }
            default:break
            }
        }
        if parentsis != 0 {
            return false
        }
        //接着解析数字
        var tempStack = [Operation]()
        var buffer:String = ""
        for op in preStack {
            switch op {
            case .operand(let value):
                buffer += "\(Int(value))"
                continue
            case .dot:
                buffer += "."
                continue
            case .e:
                tempStack.append(Operation.operand(M_E))
            case .pi:
                tempStack.append(Operation.operand(M_PI))
            default:
                if !buffer.isEmpty{
                    if let value = Double(buffer) {
                        tempStack.append(Operation.operand(value))
                        buffer = ""
                    }
                    else {
                        return false
                    }
                }
                tempStack.append(op)
            }
        }
        if let value = Double(buffer) {
            tempStack.append(Operation.operand(value))
        }
        preStack = tempStack
        return true
    }
    
    
    //前缀表达式转中缀表达式
    fileprivate func preToIn(){
        var temp = [Operation]()
        var unaryOperator:Operation?
        for op in preStack {
            //            print(op)
            switch op {
            case .operand(_):
                inStack.append(op)
                if unaryOperator != nil {
                    inStack.append(unaryOperator!)
                    unaryOperator=nil
                }
                
            case .unaryOperator(_, _):
                unaryOperator = op
            case .binaryOperator(_, _):
                if !temp.isEmpty {
                    lable: while temp.last!.compareTo(op)>=0 {
                        switch temp.last! {
                        case .parenthese(false):
                            break lable
                        default:
                            inStack.append(temp.removeLast())
                        }
                        if temp.isEmpty {
                            break
                        }
                    }
                }
                temp.append(op)
            case .parenthese(false):
                temp.append(op)
            case .parenthese(true):
                lable: while true {
                    switch temp.last! {
                    case .parenthese(false):
                        temp.removeLast()
                        break lable
                    default:
                        inStack.append(temp.removeLast())
                    }
                }
            default:
                break
            }
            //            print(temp)
            //            print(inStack)
        }
        if !temp.isEmpty {
            while true {
                if let _ = temp.last {
                    inStack.append(temp.removeLast())
                }
                else{
                    break
                }
                if !temp.isEmpty {
                    break
                }
            }
        }
    }
    
    //计算中缀表达式
    fileprivate func calculateIn() -> String?{
        var operandStack = [Double]()
        for op in inStack {
            switch op {
            case .operand(let value):
                operandStack.append(value)
            case .unaryOperator(_, let unaryOperator):
                operandStack.append(unaryOperator(operandStack.removeLast()))
            case .binaryOperator(_, let binaryOperator):
                let rightValue = operandStack.removeLast()
                let leftValue = operandStack.removeLast()
                operandStack.append(binaryOperator(leftValue,rightValue))
            default:
                break
            }
            //            print(op)
            //            print(operandStack)
        }
        if operandStack.isEmpty {
            //            print("is Empty")
            return nil
        }
        else{
            return operandStack.last?.description
        }
    }

}
