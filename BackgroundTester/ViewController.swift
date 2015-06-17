//
//  ViewController.swift
//  BackgroundTester
//
//  Created by Wolfgang Mathurin on 6/16/15.
//  Copyright (c) 2015 salesforce. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let SOUP_NAME = "logSoup";
    let INDICES = SFSoupIndex.asArraySoupIndexes([["path":"id", "type":"integer"]]);
    
    var counter  : Int = 0;
    var running : Bool = false;
    var store :  SFSmartStore!;
    var bgTask : UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid;

    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var startStopButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = UIRectEdge.None;
        
        // Database setup
        self.store = SFSmartStore.sharedGlobalStoreWithName("global") as! SFSmartStore;
        self.store.registerSoup(SOUP_NAME, withIndexSpecs: INDICES);
        
        // Reading counter from db
        self.counter = self.getCurrentCounterFromDb();
        self.counterLabel.text = String(self.counter);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func onStartStopClick(sender: AnyObject) {
        if (self.running) {
            self.running = false;
            self.startStopButton.setTitle("Start", forState: UIControlState.Normal);
        }
        else {
            startTask();
            self.running  = true;
            self.startStopButton.setTitle("Stop", forState: UIControlState.Normal);
        }
    }

    func startTask() {
        self.bgTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.bgTask);
            self.bgTask = UIBackgroundTaskInvalid;
        });
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            while (self.running) {
                var currentCounter = self.getCurrentCounterFromDb();

                if (currentCounter == -1) {
                    self.running = false;
                    break;
                }
                
                var newCounter = self.insertNext(currentCounter);
                
                if (newCounter == -1) {
                    self.running = false;
                    break;
                }
                self.counter = newCounter;
                dispatch_async(dispatch_get_main_queue(), {
                    self.counterLabel.text = String(newCounter);
                });
                NSThread.sleepForTimeInterval(0.2);
            }
        });
    }
    
    func getCurrentCounterFromDb() -> Int {
        var possibleError : NSError?;
        var currentCounter = self.store.countWithQuerySpec(SFQuerySpec.newAllQuerySpec(SOUP_NAME, withPath: "id", withOrder: SFSoupQuerySortOrder.Ascending, withPageSize: 1), error:&possibleError);
        if let error  = possibleError {
            NSLog("Failed to get count from db (%@)", error);
            return -1;
        }
        else {
            return Int(currentCounter);
        }
    }
    
    func insertNext(currentCounter : Int) -> Int {
        var possibleError : NSError?;
        var newCounter = currentCounter + 1;
        self.store.upsertEntries([["id": newCounter]], toSoup: self.SOUP_NAME, withExternalIdPath:"id", error:&possibleError);
        
        if let error = possibleError {
            NSLog("Failed to insert %d (%@)", newCounter, error);
            return -1;
        }
        else {
            NSLog("Succeeded inserting %d", newCounter);
            return newCounter;
        }
    }
    
}

