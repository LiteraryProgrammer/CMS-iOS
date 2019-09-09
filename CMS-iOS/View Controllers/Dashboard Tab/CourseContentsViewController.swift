//
//  CourseContentsViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 13/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SVProgressHUD
import SwiftKeychainWrapper
import MobileCoreServices
import RealmSwift

class CourseDetailsViewController : UITableViewController {
    
    @IBOutlet var courseLabel: UITableView!
    
    var sectionArray = [CourseSection]()
    var currentCourse = Course()
    var selectedModule = Module()
    var discussionArray = [Discussion]()
    let refreshController = UIRefreshControl()
    
    let constants = Constants.Global.self
    override func viewDidLoad() {
        
        refreshController.tintColor = .black
        refreshController.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshController
        tableView.reloadData()
        
        if sectionArray.isEmpty {
            getCourseContent { (courses) in
                self.updateUI()
                SVProgressHUD.dismiss()
            }
        }
        super.viewDidLoad()
    }
    
    func getCourseContent(completion: @escaping ([CourseSection]) -> Void) {
        
        if Reachability.isConnectedToNetwork(){
            
            let realm = try! Realm()
            let FINAL_URL = constants.BASE_URL + constants.GET_COURSE_CONTENT
            let params : [String:Any] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "courseid" : currentCourse.courseid]
            SVProgressHUD.show()
            
            Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constants.headers).responseJSON { (response) in
                if response.result.isSuccess {
                    let courseContent = JSON(response.value as Any)

                    
                    let realmSections = realm.objects(CourseSection.self).filter("courseId = \(self.currentCourse.courseid)")
                    if realmSections.count != 0{
                        try! realm.write {
                            realm.delete(realmSections)
                            // deleted
                            print("deleted preexisting objects")
                        }
                    }
                    
                    self.sectionArray.removeAll()
                    for i in 0 ..< courseContent.count {
                        if courseContent[i]["modules"].count > 0 {
                            let section = CourseSection()
                            section.name = courseContent[i]["name"].string!
                            print("module count is \(courseContent[i]["modules"].count)")
                            
                            for j in 0 ..< courseContent[i]["modules"].array!.count {
                                let moduleData = Module()
                                moduleData.modname = courseContent[i]["modules"][j]["modname"].string!
                                if moduleData.modname == "resource" {
                                    if (courseContent[i]["modules"][j]["contents"][0]["fileurl"].string!).contains("td.bits-hyderabad.ac.in") {
                                        moduleData.fileurl = (courseContent[i]["modules"][j]["contents"][0]["fileurl"].string! +
                                            "&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)")
                                        moduleData.mimetype = courseContent[i]["modules"][j]["contents"][0]["mimetype"].string!
                                        moduleData.filename = courseContent[i]["modules"][j]["contents"][0]["filename"].string!
                                    }
                                    else {
                                        moduleData.fileurl = (courseContent[i]["modules"][j]["contents"][0]["fileurl"].string!)
                                    }
                                    print(moduleData.fileurl)
                                } else if moduleData.modname == "forum" {
                                    moduleData.id = courseContent[i]["modules"][j]["instance"].int!
                                }
                                
                                
                                moduleData.name = courseContent[i]["modules"][j]["name"].string!
                                if courseContent[i]["modules"][j]["description"].string != nil {
                                    moduleData.moduleDescription = courseContent[i]["modules"][j]["description"].string!
                                }
                                section.modules.append(moduleData)
                                section.courseId = self.currentCourse.courseid
                                print(moduleData.name)
                                

                                
                            }
                            self.sectionArray.append(section)
                            try! realm.write {
                                realm.add(section)
                                print("Added section to realm")
                                
                            }
                        }
                    }
                }
                completion(self.sectionArray)
                print("function complete")
            }
            
        }
        else{
            // try to get modules from memory
            let realm = try! Realm()
            
            let sections = realm.objects(CourseSection.self).filter("courseId = \(currentCourse.courseid)")
            
            
            
            if sections.count != 0{
                sectionArray.removeAll()
                for i in 0..<sections.count{
                    sectionArray.append(sections[i])
                    print("Added to section array")
                }
            }
            
            
            
        }
    }
    
    @objc func refreshData() {
        self.refreshControl!.beginRefreshing()
        getCourseContent{ (courses) in
            self.refreshControl!.endRefreshing()
            self.tableView.reloadData()
            SVProgressHUD.dismiss()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToAnnoucements" {
            let destinationVC = segue.destination as! DiscussionTableViewController
            destinationVC.currentModule = self.selectedModule
        }
        else {
            let destinationVC = segue.destination as! ModuleViewController
            destinationVC.selectedModule = self.selectedModule
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "reuseCourse")
        cell.textLabel?.text = sectionArray[indexPath.section].modules[indexPath.row].name
        //        if sectionArray[indexPath.section].modules[indexPath.row].fileurl != "" {
        //            cell.accessoryType = .
        //        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionArray[section].modules.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionArray[section].name
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedModule = sectionArray[indexPath.section].modules[indexPath.row]
        if self.selectedModule.modname == "assign" {
            let alert = UIAlertController(title: "Unable to open assignment", message: "Assignments are not supported on the mobile version of CMS.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        }
        if selectedModule.modname == "forum" {
            performSegue(withIdentifier: "goToAnnoucements", sender: self)
        } else {
            performSegue(withIdentifier: "goToModule", sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func updateUI() {
        self.title = currentCourse.displayname

        self.tableView.reloadData()
        
    }
    
}
