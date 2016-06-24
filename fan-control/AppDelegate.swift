//
//  AppDelegate.swift
//  fan-control
//
//  Created by Harry Wang on 17/6/16.
//  Copyright © 2016 thisbetterwork. All rights reserved.
//

import Cocoa
import SMCKit

let menuBarItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
let popover = NSPopover()
var monitorLeftClick: EventMonitor?

var maxSpeed = Int(), minSpeed = Int()
var displayTemp = Bool(true), displayRPM = Bool(true), celsius = Bool(true)

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		print("hello world")
		// Initialise the button in the menubar
		if let button = menuBarItem.button {
			//			button.image = NSImage(named: "fan")
			button.action = #selector(togglePopover(_:))
			
			updateMenubarItem()
		}
		// Initialise the timer that updates the menubar every three seconds
		NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(updateMenubarItem), userInfo: nil, repeats: true)
		
		// Initialise the NSPopover to use the view controller MenuBarPopover
		popover.contentViewController = MenuBarPopover(nibName: "MenuBarPopover", bundle: nil)
		
		// Initiate the click-out monitor
		monitorLeftClick = EventMonitor(mask: .LeftMouseDownMask) { [unowned self] event in if popover.shown {self.closePopover(event)}}
		
		// get fan count, min/max speeds
		do {
			try SMCKit.open()
			
			let fanCount = try SMCKit.fanCount()
			
			if fanCount == 0 {print("No fans found, this application cannot be used."); NSApplication.sharedApplication().terminate(self)}
			
			print("identified:    \(fanCount) fan(s)\n")
			
			try maxSpeed = SMCKit.fanMaxSpeed(0)
			try minSpeed = SMCKit.fanMinSpeed(0)
			
			for i in 0..<fanCount {
				print("------ Fan ID: \(i) ------")
				print("min:           \(try SMCKit.fanMinSpeed(i)) RPM")
				print("max:           \(try SMCKit.fanMaxSpeed(i)) RPM")
				print("current:       \(try SMCKit.fanCurrentSpeed(i)) RPM")
			}
			
			SMCKit.close()
			
		} catch let err as NSError {print(err.localizedDescription);}
		print()
	}
	
	// Functions that handle the popover view.
	func showPopover(sender: AnyObject?) {if let button = menuBarItem.button {popover.showRelativeToRect(button.bounds, ofView: button, preferredEdge: NSRectEdge.MinY)}; monitorLeftClick?.start(); print("view:          was loaded")}
	func closePopover(sender: AnyObject?) {popover.performClose(sender); print("view:          was unloaded")}
	func togglePopover(sender: AnyObject?) {if popover.shown {closePopover(sender)} else {showPopover(sender)}}
	
	// updates the menubar
	func updateMenubarItem() {
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

///Class that monitors click-outs of the NSPopover.
class EventMonitor {
	private var monitor: AnyObject?
	private let mask: NSEventMask
	private let handler: NSEvent? -> ()
	
	init(mask: NSEventMask, handler: NSEvent? -> ()) {self.mask = mask; self.handler = handler}
	deinit {stop()}
	func start() {monitor = NSEvent.addGlobalMonitorForEventsMatchingMask(mask, handler: handler)}
	func stop() {if monitor != nil {NSEvent.removeMonitor(monitor!); monitor = nil}}
}

extension String {
	///Perform a regular expression (regex) operation on a string
	func regex (pattern: String) -> [String] {
		do {
			let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions(rawValue: 0))
			let nsstr = self as NSString
			let all = NSRange(location: 0, length: nsstr.length)
			var matches : [String] = [String]()
			regex.enumerateMatchesInString(self, options: NSMatchingOptions(rawValue: 0), range: all) {
				(result : NSTextCheckingResult?, _, _) in
				if let r = result {
					let result = nsstr.substringWithRange(r.range) as String
					matches.append(result)
				}
			}
			return matches
		} catch {
			return [String]()
		}
	}
}
