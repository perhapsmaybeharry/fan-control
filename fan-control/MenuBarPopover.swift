//
//  MenuBarPopover.swift
//  fan-control
//
//  Created by Harry Wang on 17/6/16.
//  Copyright © 2016 thisbetterwork. All rights reserved.
//

import Cocoa
import SMCKit

var userSetSpeed = minSpeed

class MenuBarPopover: NSViewController {

	@IBOutlet var slider: NSSlider!
	@IBOutlet var textfield: NSTextField!
	@IBOutlet var moreOptions: NSButton!
	
	override func viewDidAppear() {
		// update slider min-max values
		slider.minValue = Double(minSpeed)
		slider.maxValue = Double(maxSpeed)
		slider.doubleValue = Double(userSetSpeed)
		textfield.stringValue = String(userSetSpeed)
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(textfieldDidChangeText), name: NSControlTextDidChangeNotification, object: textfield)
		
		// sync textfield and slider
		textfield.stringValue = String(slider.integerValue)
		
		// set up moreOptions menu
		let menu = NSMenu()
		menu.addItemWithTitle("Display RPM", action: #selector(commandRPM), keyEquivalent: "r")?.state = NSOnState
		menu.addItemWithTitle("Display Temperature", action: #selector(commandTemp), keyEquivalent: "t")?.state = NSOnState
		// refresh rate?
		menu.addItem(NSMenuItem.separatorItem())
		menu.addItemWithTitle("Use Fahrenheit", action: #selector(commandToggleUnit), keyEquivalent: "u")
		menu.addItem(NSMenuItem.separatorItem())
		menu.addItemWithTitle("Auto Speed", action: #selector(commandAutoSpeed), keyEquivalent: "=")
		menu.addItemWithTitle("Full Speed", action: #selector(commandMaxSpeed), keyEquivalent: "+")
		menu.addItem(NSMenuItem.separatorItem())
		menu.addItemWithTitle("Quit", action: #selector(commandQuit), keyEquivalent: "q")
		moreOptions.menu = menu
	}
	
	// Updates the UI
	@IBAction func sliderDidChange(sender: AnyObject) {
		textfield.stringValue = String(slider.integerValue)
		setTargetFanSpeed(slider.integerValue)
	}
	@IBAction func textfieldDidFinishEditing(sender: AnyObject) {
		// allows quitting
//		if textfield.stringValue.containsString"quit") {print("goodbye world"); NSApplication.sharedApplication().terminate(self)}
		
		// sets value to either extreme end depending on which end it falls towards
		if textfield.doubleValue > slider.maxValue || textfield.doubleValue < slider.minValue {
			print("provided:      \(textfield.stringValue)")
			print("assuming:      \(textfield.doubleValue > slider.maxValue ? Int(slider.maxValue) : Int(slider.minValue))")
			textfield.stringValue = String(textfield.doubleValue > slider.maxValue ? Int(slider.maxValue) : Int(slider.minValue))
		}
		
		slider.integerValue = textfield.integerValue
		setTargetFanSpeed(slider.integerValue)
	}
	func textfieldDidChangeText() {
		// processes commands:
		// - quit (self-explanatory)
		// - rpm (display fan rpm)
		// - temp (display temperature)
		// - fah (use fahrenheit)
		// - cel (use celsius)
		// - auto (return speed control to automatic)
		// - full (full speed ahead)
		if textfield.stringValue == "quit" {commandQuit()}
		else if textfield.stringValue == "rpm" {commandRPM()}
		else if textfield.stringValue == "temp" {commandTemp()}
		else if textfield.stringValue == /*"fah"*/ "unit" {commandToggleUnit()}
//		else if textfield.stringValue == "cel" {commandToggleUnit(); return}
		else if textfield.stringValue == "auto" {commandAutoSpeed()}
		else if textfield.stringValue == "full" {commandMaxSpeed()}
		
		// if the textfield does not contain numbers, do not interpret as fan speed (to allow for incomplete commands)
		if textfield.stringValue.rangeOfCharacterFromSet(NSCharacterSet.decimalDigitCharacterSet()) != nil {
			slider.integerValue = textfield.integerValue
			setTargetFanSpeed(slider.integerValue)
		}
	}
	
	// and thus begins the commands
	func commandWasCalled() {textfield.stringValue = "\(userSetSpeed)"; updateMenubarItem()}
	func commandQuit() {print("goodbye world"); NSApp.terminate(self)}
	func commandRPM() {displayRPM = displayRPM ? false : true; print("display rpm:   \(displayRPM)"); moreOptions.menu?.itemAtIndex(0)?.state = displayRPM ? NSOnState : NSOffState; commandWasCalled()}
	func commandTemp() {displayTemp = displayTemp ? false : true; print("display temp:  \(displayTemp)"); moreOptions.menu?.itemAtIndex(1)?.state = displayTemp ? NSOnState : NSOffState;  commandWasCalled()}
//	func commandCelsius() {celsius = true; print("unit:          celsius"); moreOptions.menu?.itemAtIndex(3)?.state = celsius ? NSOnState : NSOffState; commandWasCalled()}
//	func commandFahrenheit() {celsius = false; print("unit:          fahrenheit"); moreOptions.menu?.itemAtIndex(4)?.state = celsius ? NSOffState : NSOnState; commandWasCalled()}
	func commandToggleUnit() {if celsius {celsius = false; moreOptions.menu?.itemAtIndex(3)?.title = "Use Celsius"} else {celsius = true; moreOptions.menu?.itemAtIndex(3)?.title = "Use Fahrenheit"}; print("unit:          \(celsius ? "celsius" : "fahrenheit")"); commandWasCalled()}
	func commandAutoSpeed() {slider.doubleValue = slider.minValue; textfield.stringValue = String(slider.integerValue); setTargetFanSpeed(Int(slider.minValue))}
	func commandMaxSpeed() {slider.doubleValue = slider.maxValue; textfield.stringValue = String(slider.integerValue); setTargetFanSpeed(Int(slider.maxValue))}
	
	// stupid selectors that don't accept parameters won't let me use this
//	func commandUnit(unit: String) {celsius = unit == "cel" ? true : false; print("unit:          \(celsius ? "celsius" : "fahrenheit")"); commandWasCalled()}
	
	// Co-ordinating function that prints and sets the target fan speed
	func setTargetFanSpeed(targetSpeed: Int) {
		printTargetValue(targetSpeed)
		actuallySetFanSpeed(targetSpeed)
		userSetSpeed = targetSpeed
	}
	
	// Fun little function that gives the debug menu an idea of what's going on
	private func printTargetValue(targetSpeed: Int) {print("target:        \(targetSpeed) RPM")}
	
	// Serious function that is the core of this entire program!
	private func actuallySetFanSpeed(targetSpeed: Int) {
		do {
			
			try SMCKit.open()
			let fanCount = try SMCKit.fanCount()
			for i in 0..<fanCount {
//				print("Setting fan \(i) to \(targetSpeed)")
				
				// Need to fix not-privileged error. As of now, this error can be circumnavigated by launching the command executable with sudo like so:
				// sudo fan-control.app/Contents/Resources/MacOS/fan-control
				// In the end I went with an applescript launch wrapper "with administrator privileges"
				try SMCKit.fanSetMinSpeed(i, speed: targetSpeed)
			}
			SMCKit.close()
			
		} catch SMCKit.Error.NotPrivileged {print("The application must be invoked with `sudo` to function correctly")} catch let err as NSError {print(err.localizedDescription)}
	}
	
	// updates the menubar. is an exact duplicate of the one in AppDelegate and is here for convenience purposes.
	private func updateMenubarItem() {
		do {
			menuBarItem.button!.title = ""
			try SMCKit.open()
			if displayTemp && celsius {menuBarItem.button!.title.appendContentsOf("\(Int(try SMCKit.temperature(FourCharCode(fromStaticString: "TC0F"))))ºC ")}
			else if displayTemp && !celsius {menuBarItem.button!.title.appendContentsOf("\(Int(try SMCKit.temperature(FourCharCode(fromStaticString: "TC0F"), unit: TemperatureUnit.Fahrenheit)))ºF ")}
			if displayRPM {menuBarItem.button!.title.appendContentsOf("\(try SMCKit.fanCurrentSpeed(0)) rpm")}
			SMCKit.close()
		} catch let err as NSError {print(err.localizedDescription)}
		menuBarItem.button!.font = NSFont(name: "Menu Bar", size: 24)
	}

	
}
