//
//  ViewController.swift
//  AutoFill
//
//  Created by hemenisapp on 9.07.2020.
//  Copyright © 2020 hemenisapp. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var textField: UITextField = {
        let field = UITextField()
        field.font = .systemFont(ofSize: 24)
        field.defaultTextAttributes.updateValue(8, forKey: NSAttributedString.Key.kern)
        field.frame = CGRect(x: 50, y: 250, width: 300, height: 40)
        field.backgroundColor = .lightGray
        return field
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let view = PasscodeView()
        view.delegate = self
        self.view.addSubview(view)
        
        view.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        view.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
    }
}

extension ViewController: PasscodeViewDelegate {
    
    func passcodeView(_ passcodeView: PasscodeView, didEntered passcode: String) {
        print("passcode received \(passcode)")
        print(passcode)
    }
    
}

protocol PasscodeViewDelegate {
    func passcodeView(_ passcodeView: PasscodeView, didEntered passcode: String)
}

class PasscodeView: UIStackView {
    
    private var numberOfFields: Int = 6
    private var fields: [PasscodeField] = []
    var delegate: PasscodeViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var passcode: String {
        return self.fields.passcode
    }
    
    func configure() {
        self.fieldGenerator()
        self.fields.first?.becomeFirstResponder()
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.axis = .horizontal
        self.alignment = .center
        self.distribution = .equalSpacing
        self.spacing = 8
        self.backgroundColor = .yellow
        
        self.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0).isActive = true
        self.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0).isActive = true
    }
    
    
    
    private func fieldGenerator() {
        for i in 0..<self.numberOfFields {
            
            let field = PasscodeField()
        
            field.tag = i
            field.passcodeDelegate = self
            
            field.previousField = self.fields.last
            self.fields.last?.nextField = field
            
            field.heightAnchor.constraint(equalToConstant: 40).isActive = true
            field.widthAnchor.constraint(equalToConstant: 40).isActive = true
            
            self.fields.append(field)
            self.addArrangedSubview(field)
        }
    }
}

extension PasscodeView: PasscodeFieldDelegate {
    
    func passcodeField(_ passcodeField: PasscodeField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        #warning("fix first responder")
        #warning("move decision of target to field itself")
        
        guard !string.isEmpty else {
            passcodeField.text = ""
            return false
        }
        
        guard string.count == 1 else {
            let numbers = string.numbersOnly
            if numbers.count != self.numberOfFields { return false }
            
            for (index, number) in numbers.enumerated() {
                self.fields[index].text = String(number)
            }
            
            self.fields.last?.becomeFirstResponder()
            self.delegate?.passcodeView(self, didEntered: self.passcode)
            
            return false
        }
        
        passcodeField.nextField?.becomeFirstResponder()
        
        guard passcodeField.text?.count == 0 else {
            passcodeField.nextField?.setText(with: string)
            return false
        }
        
        passcodeField.text = string
        
        guard passcodeField != self.fields.last else {
            self.delegate?.passcodeView(self, didEntered: self.passcode)
            return false
        }
        
        return false
    }
    
    
    func passcodeFieldDidPressedBackspace(_ passcodeField: PasscodeField) {
        if let previous = passcodeField.previousField {
            previous.text = ""
            previous.becomeFirstResponder()
        }
    }
}

extension String {
    
    var numbersOnly: String {
        let pattern = UnicodeScalar("0")..."9"
        return String(unicodeScalars.compactMap { pattern ~= $0 ? Character($0) : nil })
    }
    
    func enumerateNumbers(_ iterator: (Int, String) -> Void) {
        for number in self.numbersOnly.enumerated() {
            iterator(number.offset, String(number.element))
        }
    }
}

protocol PasscodeFieldDelegate: UITextFieldDelegate {
    func passcodeFieldDidPressedBackspace(_ passcodeField: PasscodeField)
    func passcodeField(_ passcodeField: PasscodeField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    //func passcodeFieldDidEndEditing(_ passcodeField: PasscodeField)
}
 
public class PasscodeField: UITextField {
    
    var passcodeDelegate: PasscodeFieldDelegate?

    weak var nextField: PasscodeField?
    weak var previousField: PasscodeField?
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate = self
        self.configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        self.attributedPlaceholder = NSAttributedString(
            string: "•",
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.black,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 24)
            ]
        )
        self.backgroundColor = .gray
        self.layer.cornerRadius = 6
        self.clipsToBounds = true
        self.keyboardType = .decimalPad
        self.textAlignment = .center
        self.font = .systemFont(ofSize: 24)
        self.tintColor = .systemPink
        self.isUserInteractionEnabled = false
        self.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 12.0, *) {
            self.textContentType = .oneTimeCode
        }
    }
    
    public override func deleteBackward() {
        super.deleteBackward()
        passcodeDelegate?.passcodeFieldDidPressedBackspace(self)
    }
    
    public func setText(with text: String) {
        print("setting text \(text)")
        self.text = text
    }
}

extension PasscodeField: UITextFieldDelegate {
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return passcodeDelegate?.passcodeField(self, shouldChangeCharactersIn: range, replacementString: string) ?? false
    }
}

extension Array where Element: PasscodeField {
    
    var passcode: String {
        return self.reduce(into: String()) { (passcode, field) in
            print("code \(passcode) field \(field.tag) text \(field.text)")
            passcode.append(field.text ?? "")
        }
    }
    
}
