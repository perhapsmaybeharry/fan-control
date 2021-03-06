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
	
	let optionsMenu = NSMenu(), presetSubMenu = NSMenu()
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
		optionsMenu.removeAllItems()
		optionsMenu.addItemWithTitle("Display RPM", action: #selector(commandRPM), keyEquivalent: "r")?.state = NSOnState
		optionsMenu.addItemWithTitle("Display Temperature", action: #selector(commandTemp), keyEquivalent: "t")?.state = NSOnState
		// allow changing of sensor used for temperature?
		optionsMenu.addItem(NSMenuItem.separatorItem())
		optionsMenu.addItemWithTitle("Presets", action: nil, keyEquivalent: "")
		// set up presets submenu
		presetSubMenu.autoenablesItems = false
		loadPresets()
		optionsMenu.setSubmenu(presetSubMenu, forItem: optionsMenu.itemWithTitle("Presets")!)
		optionsMenu.addItem(NSMenuItem.separatorItem())
		optionsMenu.addItemWithTitle("Use Fahrenheit", action: #selector(commandToggleUnit), keyEquivalent: "u")
		optionsMenu.addItem(NSMenuItem.separatorItem())
		optionsMenu.addItemWithTitle("Auto Speed", action: #selector(commandAutoSpeed), keyEquivalent: "=")
		optionsMenu.addItemWithTitle("Full Speed", action: #selector(commandMaxSpeed), keyEquivalent: "+")
		optionsMenu.addItem(NSMenuItem.separatorItem())
		optionsMenu.addItemWithTitle("Quit", action: #selector(commandQuit), keyEquivalent: "q")
		moreOptions.menu = optionsMenu
	}
	
//	// presets...ugh
//	func loadPresets() {
//		var presetFile = String(), presets = [String]()
//		do {presetFile = try String(contentsOfFile: NSBundle.mainBundle().pathForResource("pst", ofType: "")!)} catch let err as NSError {print(err.localizedDescription)}
//		if !presetFile.containsString("][") {presetSubMenu.addItemWithTitle("No presets", action: nil, keyEquivalent: ""); presetSubMenu.autoenablesItems = false; presetSubMenu.itemWithTitle("No presets")!.enabled = false; return} else {presetSubMenu.removeAllItems()}
//		presets = presetFile.componentsSeparatedByString("][")
//		for preset in presets {
//			presetSubMenu.addItemWithTitle("\(preset) rpm", action: #selector(menuChangeRPMToPreset(_:)), keyEquivalent: "")
//		}
//		presetSubMenu.addItem(NSMenuItem.separatorItem())
//		presetSubMenu.addItemWithTitle("Save Current Settings", action: #selector(writePreset), keyEquivalent: "")
//	}
//	func writePreset() {
//		do {try String("\(userSetSpeed)][").writeToFile("\(NSBundle.mainBundle().resourcePath!)/pst", atomically: false, encoding: NSUTF8StringEncoding)} catch let err as NSError {print(err.localizedDescription)}
//		loadPresets()
//	}
	
	// another try at presets
	func writePreset() {
		// procedure: check if file exists, if not {create}, then check if duplicate, then write
		if !NSFileManager().fileExistsAtPath("\(NSBundle.mainBundle().resourcePath!)/pst") {print("presets:       creating file"); NSFileManager().createFileAtPath("\(NSBundle.mainBundle().resourcePath!)/pst", contents: NSData(), attributes: nil)}
		do {if try String(contentsOfFile: "\(NSBundle.mainBundle().resourcePath!)/pst").containsString("\(userSetSpeed)") {print("presets:       \(userSetSpeed) rpm already exists"); return}} catch let err as NSError {print(err.localizedDescription)}
		print("presets:       saving \(userSetSpeed) rpm")
		do {try String("\(try String(contentsOfFile: "\(NSBundle.mainBundle().resourcePath!)/pst"))\(userSetSpeed)][").writeToFile("\(NSBundle.mainBundle().resourcePath!)/pst", atomically: false, encoding: NSUTF8StringEncoding)} catch let err as NSError {print(err.localizedDescription)}
		loadPresets()
	}
	func loadPresets() {
		// procedure: clear and load presets one by one into the menu
		presetSubMenu.removeAllItems()
		do {let presets = try String(contentsOfFile: "\(NSBundle.mainBundle().resourcePath!)/pst").componentsSeparatedByString("][").dropLast()
			for preset in presets {
				print("presets:       loading preset \(preset) rpm")
				presetSubMenu.addItemWithTitle("\(preset) RPM", action: #selector(setToPreset(_:)), keyEquivalent: "")
			}} catch let err as NSError {print(err.localizedDescription)}
		presetSubMenu.addItem(NSMenuItem.separatorItem())
		presetSubMenu.addItemWithTitle("Save Current Settings", action: #selector(writePreset), keyEquivalent: "")
		presetSubMenu.addItemWithTitle("Delete Current Preset", action: #selector(deletePreset), keyEquivalent: "")
	}
	func setToPreset(sender: NSMenuItem) {
		let newRPM = Int(sender.title.componentsSeparatedByString(" ")[0])!
		print("presets:       using preset \(newRPM)")
		slider.integerValue = newRPM
		textfield.stringValue = "\(newRPM)"
		setTargetFanSpeed(newRPM)
		for i in 0..<presetSubMenu.itemArray.count {presetSubMenu.itemAtIndex(i)!.state = NSOffState}
		sender.state = NSOnState
	}
	func deletePreset() {for i in presetSubMenu.itemArray {if i.state == NSOnState {presetSubMenu.removeItem(i)}}}
	
	// Updates the UI
	@IBAction func sliderDidChange(sender: AnyObject) {
		textfield.stringValue = String(slider.integerValue)
		setTargetFanSpeed(slider.integerValue)
		// no longer on preset mode!
		for i in 0..<presetSubMenu.itemArray.count {presetSubMenu.itemAtIndex(i)!.state = NSOffState}
	}
	@IBAction func textfieldDidFinishEditing(sender: AnyObject) {
		// allows quitting
//		if textfield.stringValue.containsString"quit") {print("goodbye world"); NSApplication.sharedApplication().terminate(self)}
		
		// sets value to either extreme end depending on which end it falls towards
		if textfield.doubleValue > slider.maxValue || textfield.doubleValue < slider.minValue {
			print("provided:      \(textfield.stringValue)")
//			print("assuming:      \(textfield.doubleValue > slider.maxValue ? Int(slider.maxValue) : Int(slider.minValue))")
			textfield.stringValue = String(textfield.doubleValue > slider.maxValue ? Int(slider.maxValue) : Int(slider.minValue))
		}
		
		slider.integerValue = textfield.integerValue
		setTargetFanSpeed(slider.integerValue)
	}
	func textfieldDidChangeText() {
		// no longer on preset mode!
		for i in 0..<presetSubMenu.itemArray.count {presetSubMenu.itemAtIndex(i)!.state = NSOffState}
		// processes commands:
		// - quit (self-explanatory)
		// - rpm (display fan rpm)
		// - temp (display temperature)
		// - fah (use fahrenheit) [DEPRECATED]
		// - cel (use celsius) [DEPRECATED]
		// - unit
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
	func commandQuit() {NSApp.terminate(self)}
	func commandRPM() {displayRPM = displayRPM ? false : true; print("display rpm:   \(displayRPM)"); moreOptions.menu?.itemAtIndex(0)?.state = displayRPM ? NSOnState : NSOffState; commandWasCalled()}
	func commandTemp() {displayTemp = displayTemp ? false : true; print("display temp:  \(displayTemp)"); moreOptions.menu?.itemAtIndex(1)?.state = displayTemp ? NSOnState : NSOffState;  commandWasCalled()}
//	func commandCelsius() {celsius = true; print("unit:          celsius"); moreOptions.menu?.itemAtIndex(3)?.state = celsius ? NSOnState : NSOffState; commandWasCalled()}
//	func commandFahrenheit() {celsius = false; print("unit:          fahrenheit"); moreOptions.menu?.itemAtIndex(4)?.state = celsius ? NSOffState : NSOnState; commandWasCalled()}
	func commandToggleUnit() {if celsius {celsius = false; moreOptions.menu?.itemAtIndex(3)?.title = "Use Celsius"} else {celsius = true; moreOptions.menu?.itemAtIndex(3)?.title = "Use Fahrenheit"}; print("unit:          \(celsius ? "celsius" : "fahrenheit")"); commandWasCalled()}
	func commandAutoSpeed() {slider.doubleValue = slider.minValue; textfield.stringValue = String(slider.integerValue); setTargetFanSpeed(Int(slider.minValue))}
	func commandMaxSpeed() {slider.doubleValue = slider.maxValue; textfield.stringValue = String(slider.integerValue); setTargetFanSpeed(Int(slider.maxValue))}
//	func menuChangeRPMToPreset(sender: NSMenuItem) {print(sender.title); setTargetFanSpeed(Int(sender.title)!)}
	
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
