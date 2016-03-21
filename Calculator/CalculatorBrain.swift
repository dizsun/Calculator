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
    //计算器的输入有三类：数字、一元运算符、二元运算符
    private enum Op: CustomStringConvertible {
        case Operand(Double)    //运算数字
        case UnaryOperation(String,Double->Double)  //一元运算符
        case BinaryOperation(String,(Double,Double)->Double)    //二元运算符
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
                }
            }
        }
    }
    //盛放输入内容的栈
    private var opStack = [Op]()
    //所有会用到的运算符集合
    private var knownOps = [String:Op]()
    
    init(){
        knownOps["×"] = Op.BinaryOperation("×", *)
        knownOps["÷"] = Op.BinaryOperation("÷"){ $1 / $0 }
        knownOps["+"] = Op.BinaryOperation("+", *)
        knownOps["−"] = Op.BinaryOperation("−"){ $1 - $0 }
        knownOps["√"] = Op.UnaryOperation("√", sqrt)
    }
    
    typealias ProperList = AnyObject
    
    var program: ProperList {
        get{
            return opStack.map{ $0.description }
        }
        set{
            if let opSymbols = newValue as? Array<String> {
                var newOpStack = [Op]()
                for opSymbol in opSymbols{
                    if let op = knownOps[opSymbol]{
                        newOpStack.append(op)
                    }
                    else if let operand = Double.init(opSymbol){
                        newOpStack.append(.Operand(operand))
                    }
                }
                opStack = newOpStack
            }
        }
    }
    
    
    //对栈中内容进行计算的函数，运用递归调用计算所有值
    private func evaluate(ops:[Op]) -> (result: Double?, remainingOps: [Op]){
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand):
                return (operand, remainingOps)
            case .UnaryOperation(_, let operation):
                let operandEvaluation = evaluate(remainingOps)
                if let operand = operandEvaluation.result{
                    return (operation(operand),operandEvaluation.remainingOps)
                }
            case .BinaryOperation(_, let operation):
                let op1Evaluation = evaluate(remainingOps)
                if let operand1 = op1Evaluation.result{
                    let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                    if let operand2 =  op2Evaluation.result{
                        return (operation(operand1,operand2), op2Evaluation.remainingOps)
                    }
                }
            }
        }
        return (nil, ops)
    }
    
    func evaluate() -> Double?{
        let (result, _) = evaluate(opStack)
        return result
    }
    //将运算数字压入栈中，并返回计算值
    func pushOperand(operand: Double?) -> Double?{
        guard let operandValue = operand else{
            return nil
        }
        opStack.append(Op.Operand(operandValue))
        return evaluate()
    }
    //将运算符压入栈中并求值
    func performOperation(symbol: String) -> Double?{
        if let operation = knownOps[symbol]{
            opStack.append(operation)
        }
        return evaluate()
    }
}