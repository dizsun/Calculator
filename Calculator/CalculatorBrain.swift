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
    private enum Operation: CustomStringConvertible {
        case Operand(Double)    //运算数字
        case UnaryOperator(String,Double->Double)  //一元运算符
        case BinaryOperator(String,(Double,Double)->Double)    //二元运算符
        case Dot
        case Parenthese(Bool)//括号，如果Parenthese的值是true则为)否则为(
        case PI
        case E
        //Op的toString方法
        var description:String{
            get{
                switch self{
                case .Operand(let operand):
                    return "\(operand)"
                case .UnaryOperator(let operation, _):
                    return "\(operation)"
                case .BinaryOperator(let operation, _):
                    return "\(operation)"
                case .Dot:
                    return "."
                case .Parenthese(let direction):
                    if direction {
                        return ")"
                    }
                    else{
                        return "("
                    }
                case .PI:
                    return "pi"
                case .E:
                    return "e"
                }
            }
        }
        //运算符的比较，+，-运算优先级最小为0，*，/为1，^为2，单目运算符为3
        func compareTo(other:Operation) -> Int {
            let priority = [ "+":0, "−":0, "×":1, "÷":1, "^":2, "√":3, "log":3, "ln":3, "sin":3, "cos":3, "tan":3 ]
            if priority.keys.contains(self.description)
                && priority.keys.contains(other.description) {
                return priority[self.description]! - priority[other.description]!
            }
            return 0
        }
    }
    //盛放输入内容的栈
    private var preStack = [Operation]()
    //所有会用到的运算符集合
    private var knownOps = [String:Operation]()
    
    init(){
        knownOps["+"] = Operation.BinaryOperator("+", +)
        knownOps["−"] = Operation.BinaryOperator("−", -)
        knownOps["×"] = Operation.BinaryOperator("×", *)
        knownOps["÷"] = Operation.BinaryOperator("÷", /)
        knownOps["^"] = Operation.BinaryOperator("^", pow)
        knownOps["√"] = Operation.UnaryOperator("√", sqrt)
        knownOps["log"] = Operation.UnaryOperator("log", log2)
        knownOps["ln"] = Operation.UnaryOperator("ln", log)
        knownOps["sin"] = Operation.UnaryOperator("sin", sin)
        knownOps["cos"] = Operation.UnaryOperator("cos", cos)
        knownOps["tan"] = Operation.UnaryOperator("tan", tan)
        knownOps["("] = Operation.Parenthese(false)
        knownOps[")"] = Operation.Parenthese(true)
        knownOps["."] = Operation.Dot
        knownOps["e"] = Operation.E
        knownOps["pi"] = Operation.PI
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
    func pushOperand(operand: String){
        if knownOps.keys.contains(operand) {
            preStack.append(knownOps[operand]!)
        }
        else{
            preStack.append(Operation.Operand(Double(operand)!))
        }
    }

    //将输入的数字或运算符删除一个
    func popOperand() -> String {
        if preStack.count > 0 {
            if let value = preStack.popLast(){
                return value.description
            }
            else{
                return ""
            }
        }
        return ""
    }
    //将输入的内容清零
    func clearOpSatck(){
        preStack.removeAll()
    }
    //MARK: 运算逻辑
    //中缀表达式
    private var inStack = [Operation]()
    //算式解析，将数字拼在一起，将E与PI替换成数字
    private func parseFormula() -> Bool {
        //首先判断括号是否一一匹配
        var parentsis = 0
        for op in preStack {
            switch op {
            case .Parenthese(let direction):
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
            case .Operand(let value):
                buffer += "\(Int(value))"
                continue
            case .Dot:
                buffer += "."
                continue
            case .E:
                tempStack.append(Operation.Operand(M_E))
            case .PI:
                tempStack.append(Operation.Operand(M_PI))
            default:
                if !buffer.isEmpty{
                    if let value = Double(buffer) {
                        tempStack.append(Operation.Operand(value))
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
            tempStack.append(Operation.Operand(value))
        }
        preStack = tempStack
        return true
    }
    
    
    //前缀表达式转中缀表达式
    private func preToIn(){
        var temp = [Operation]()
        var unaryOperator:Operation?
        for op in preStack {
            //            print(op)
            switch op {
            case .Operand(_):
                inStack.append(op)
                if unaryOperator != nil {
                    inStack.append(unaryOperator!)
                    unaryOperator=nil
                }
                
            case .UnaryOperator(_, _):
                unaryOperator = op
            case .BinaryOperator(_, _):
                if !temp.isEmpty {
                    lable: while temp.last!.compareTo(op)>=0 {
                        switch temp.last! {
                        case .Parenthese(false):
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
            case .Parenthese(false):
                temp.append(op)
            case .Parenthese(true):
                lable: while true {
                    switch temp.last! {
                    case .Parenthese(false):
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
    private func calculateIn() -> String?{
        var operandStack = [Double]()
        for op in inStack {
            switch op {
            case .Operand(let value):
                operandStack.append(value)
            case .UnaryOperator(_, let unaryOperator):
                operandStack.append(unaryOperator(operandStack.removeLast()))
            case .BinaryOperator(_, let binaryOperator):
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