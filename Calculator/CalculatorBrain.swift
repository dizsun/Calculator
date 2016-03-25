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
    private enum Op: CustomStringConvertible {
        case Operand(Double)    //运算数字
        case UnaryOperation(String,Double->Double)  //一元运算符
        case BinaryOperation(String,(Double,Double)->Double)    //二元运算符
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
                case .UnaryOperation(let operation, _):
                    return "\(operation)"
                case .BinaryOperation(let operation, _):
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
        func compareTo(other:Op) -> Int {
            let priority = [ "+":0, "−":0, "×":1, "÷":1, "^":2, "√":3, "log":3, "ln":3, "sin":3, "cos":3, "tan":3 ]
            if priority.keys.contains(self.description)
                && priority.keys.contains(other.description) {
                return priority[self.description]! - priority[other.description]!
            }
            return 0
        }
    }
    //盛放输入内容的栈
    private var opStack = [Op]()
    //所有会用到的运算符集合
    private var knownOps = [String:Op]()
    
    init(){
        knownOps["+"] = Op.BinaryOperation("+", +)
        knownOps["−"] = Op.BinaryOperation("−", -)
        knownOps["×"] = Op.BinaryOperation("×", *)
        knownOps["÷"] = Op.BinaryOperation("÷", /)
        knownOps["^"] = Op.BinaryOperation("^", pow)
        knownOps["√"] = Op.UnaryOperation("√", sqrt)
        knownOps["log"] = Op.UnaryOperation("log", log2)
        knownOps["ln"] = Op.UnaryOperation("ln", log)
        knownOps["sin"] = Op.UnaryOperation("sin", sin)
        knownOps["cos"] = Op.UnaryOperation("cos", cos)
        knownOps["tan"] = Op.UnaryOperation("tan", tan)
        knownOps["("] = Op.Parenthese(false)
        knownOps[")"] = Op.Parenthese(true)
        knownOps["."] = Op.Dot
        knownOps["e"] = Op.E
        knownOps["pi"] = Op.PI
    }
    //MARK: 接口函数
    //计算算式值
    func evaluate() -> Double?{
        if !parseFormula() {
            return nil
        }
        return evaluate(opStack)
    }
    //将运算数字或运算符压入栈中
    func pushOperand(operand: String){
        if knownOps.keys.contains(operand) {
            opStack.append(knownOps[operand]!)
        }
        else{
            opStack.append(Op.Operand(Double(operand)!))
        }
    }
    //将输入的数字或运算符删除一个
    func popOperand() -> String {
        if opStack.count > 0 {
            if let value = opStack.popLast(){
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
        opStack.removeAll()
    }
    //MARK: 运算逻辑
    //将括号完全去除得到简单算式
    private func evaluate(ops:[Op]) -> Double? {
        if ops.isEmpty {
            return 0
        }
        var hasParenthese = false //算式中是否含有括号
        label: for op in ops {
            switch op {
            case .Parenthese(_):
                hasParenthese = true
                break label
            default:break
            }
        }
        if hasParenthese {
            var tempStack = [Op]()
            for var i=0; i<ops.count; i++ {
                switch ops[i] {
                case .Parenthese(_):
                    guard let rightIndex = findMatchingParenthese(ops, index: i) else{
                        return nil
                    }
                    guard let innnerFormula = getFormulaInRange(ops, preIndex: i, postIndex: rightIndex) else {
                        return nil
                    }
                    i = rightIndex
                    guard let innnerValue = evaluate(innnerFormula) else{
                        return nil
                    }
                    tempStack.append(Op.Operand(innnerValue))
                default: tempStack.append(ops[i])
                }
            }
            return evaluate(tempStack)
        }
        else{
            return evaluateSimpleFormula(ops)
        }
    }
    //计算简单算式
    private func evaluateSimpleFormula(ops:[Op]) -> Double? {
        let rightStack = middleToPost(ops)
        return evaluateRightFormula(rightStack)
    }
    //将中序表达式变换为后序表达式
    private func middleToPost(initialSatck: [Op]) -> [Op] {
        var postStack = [Op]()
        var tempStack = [Op]()
        for var eachOp in initialSatck {
            switch eachOp {
            case .Operand(_):
                postStack.append(eachOp)
            case .Parenthese(let direction):
                if !direction {
                    tempStack.append(eachOp)
                }
                else{
                    var tempValue = tempStack.removeLast()
                    var value = tempValue.description
                    while value != Op.Parenthese(true).description {
                        postStack.append(tempValue)
                        tempValue = tempStack.removeLast()
                        value = tempValue.description
                    }
                }
            case .BinaryOperation(_, _):
                if tempStack.isEmpty {
                    tempStack.append(eachOp)
                }
                else{
                    if eachOp.compareTo(tempStack.last!) > 0 {
                        tempStack.append(eachOp)
                    }
                    else{
                        while !tempStack.isEmpty && eachOp.compareTo(tempStack.last!) <= 0 {
                            postStack.append(tempStack.removeLast())
                        }
                        tempStack.append(eachOp)
                    }
                }
            case .UnaryOperation(_, _):
                tempStack.append(eachOp)
            default:
                break
            }
        }
        while !tempStack.isEmpty {
            postStack.append(tempStack.removeLast())
        }
        return postStack
    }
    //计算后序表达式
    private func evaluateRightFormula(rightStack: [Op]) -> Double?{
        var tempStack = [Double]()
        for var i=0; i<rightStack.count; i++ {
            switch rightStack[i] {
            case .Operand(let value):
                tempStack.append(value)
            case .BinaryOperation(_, let perform):
                let rightValue = tempStack.removeLast()
                let leftValue = tempStack.removeLast()
                let result = perform(leftValue,rightValue)
                tempStack.append(result)
            case .UnaryOperation(_, let perform):
                let result = perform(tempStack.removeLast())
                tempStack.append(result)
            default: break
            }
        }
        if tempStack.isEmpty {
            return nil
        }
        else{
            return tempStack.removeLast()
        }
    }
    //将opStack中的分离的数字解析为一个数字
    private func parseFormula() -> Bool {
        //首先判断括号是否一一匹配
        var parentsis = 0
        for var i=0; i<opStack.count; i++ {
            switch opStack[i] {
            case .Parenthese(let direction):
                if direction {
                    parentsis--
                }
                else{
                    parentsis++
                }
            default:break
            }
        }
        if parentsis != 0 {
            return false
        }
        //接着解析数字
        var tempStack = [Op]()
        var buffer:String = ""
        for var i=0;i<opStack.count;i++ {
            switch opStack[i] {
            case .Operand(let value):
                buffer += "\(Int(value))"
                continue
            case .Dot:
                buffer += "."
                continue
            case .E:
                buffer = "\(M_E)"
            case .PI:
                buffer = "\(M_PI)"
            default:
                if !buffer.isEmpty{
                    if let value = Double(buffer) {
                        tempStack.append(Op.Operand(value))
                        buffer = ""
                    }
                    else {
                        return false
                    }
                }
                tempStack.append(opStack[i])
            }
        }
        if let value = Double(buffer) {
            tempStack.append(Op.Operand(value))
        }
        opStack = tempStack
        return true
    }
    //找到与左括号匹配的那个右括号的索引,若不存在则返回nil
    private func findMatchingParenthese(ops:[Op], index: Int) -> Int? {
        var count = 1
        for var i = index+1; i<ops.count; i++ {
            switch ops[i] {
            case .Parenthese(false): count++
            case .Parenthese(true): count--
            default: break
            }
            if count == 0 {
                return i
            }
        }
        return nil
    }
    //得到括号内的算式，左右索引均为开区间，如果括号内没有值则返回0，如果算式有误返回nil
    private func getFormulaInRange(ops:[Op], preIndex:Int, postIndex: Int) -> [Op]?{
        if preIndex >= postIndex+1 {
            return nil
        }
        var tempStack = [Op]()
        for var i=preIndex+1; i<postIndex; i++ {
            tempStack.append(ops[i])
        }
        return tempStack
    }

}