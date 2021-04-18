//
//  CohesionAssessmentTests.swift
//  CohesionAssessmentTests
//
//  Created by B on 4/18/21.
//

import XCTest
import UIKit
import MapKit
@testable import CohesionAssessment

class CohesionAssessmentTests: XCTestCase {
    
    var viewControllerUnderTest : ViewController!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        super.setUp()
        
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        viewControllerUnderTest = storyboard.instantiateViewController(identifier: "ViewController") as ViewController
        
        if viewControllerUnderTest != nil {
            viewControllerUnderTest.loadView()
            viewControllerUnderTest.viewDidLoad()
        }
        
    }
    
    func test_MapView() {
        
        // ViewController is composed of MapView
        XCTAssertNotNil(viewControllerUnderTest.mapView, "ViewController is not composed of a MKMapView")
        
        // ViewController conforms MapViewDelegate
        XCTAssert(viewControllerUnderTest.conforms(to: MKMapViewDelegate.self), "ViewController does not conform to MKMapViewDelegate protocol")
        
        XCTAssertNotNil(self.viewControllerUnderTest.mapView.delegate)
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        viewControllerUnderTest = nil
        
        super.tearDown()
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
