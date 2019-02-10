//
//  ViewController.swift
//  Dimentia App
//
//  Created by Harrison Nathan Lee on 2019-02-09.
//  Copyright © 2019 Harrison Nathan Lee. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation
import Speech
//import Alamofire

//struct story_item : Codable{
//    let questions: Set<String>
//    let answers: Set<String>
//}

struct Answer: Codable{
    let questionId: Int
    let patientId: Int
    let answer: String
//    let voice: String
}

struct Question: Decodable{
    let text: String
    let patientId: Int?
    let id: Int
    let image: String?
    let type: String
    let speech: String?
}

class ViewController: UIViewController, AVAudioRecorderDelegate, UITextFieldDelegate,
SFSpeechRecognizerDelegate {
    @IBOutlet var textBox: UITextField!
    //    @IBOutlet var textBox: UITextView!
    @IBOutlet var typeButton: UIButton!
    @IBOutlet var questionLabel: UILabel!

    @IBOutlet var microphoneButton: UIButton!
    @IBOutlet var PlayOutlet: UIButton!
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioFromServer: AVAudioPlayer?
    var audioFilename: URL!
    var questionID: Int!
    var questionCont: Int!
    var textAnswer: String!
    var player: AVPlayer!
    
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine : AVAudioEngine!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))  //1
    
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record, mode: .default)
            // setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
//        guard let inputNode = audioEngine!.inputNode else {
//            fatalError("Audio engine has no input node")
//        }

        let inputNode = audioEngine!.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer!.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.textBox.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
//        textBox.text = "Say something, I'm listening!"
        
    }
    
    
//    @IBOutlet var textfieldoutlet: [UITextView]!
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textfieldshouldreturn")
        if textField.returnKeyType == UIReturnKeyType.send {
            textField.resignFirstResponder()
            print("send worked")
            enterTapped()
            return true
        }
        return false
    }
    
    @IBAction func microphoneClicked(_ sender: Any) {
        if audioEngine.isRunning {
            
            textBox.resignFirstResponder()
            
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start Recording", for: .normal)
            
//            enterTapped()
            
            
        } else {
            textBox.isHidden = false
            textBox.becomeFirstResponder()
            
            startRecording()
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
    
    override func viewDidLoad() {
        //assigning delegates
        super.viewDidLoad()
        
        
        audioEngine = AVAudioEngine()
        
        microphoneButton.isEnabled = false  //2
        
        speechRecognizer!.delegate = self  //3
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            
            var isButtonEnabled = false
            
            switch authStatus {  //5
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
        
        recordingSession = AVAudioSession.sharedInstance()
        questionLabel.center.x = self.view.center.x
        textBox.delegate = self
        self.textBox.isHidden = true
        
        changeQuestion()
        
        

//        do{
//            try recordingSession.setCategory(.playAndRecord, mode: .default)
//            try recordingSession.setActive(true)
//            recordingSession.requestRecordPermission() { [unowned self] allowed in DispatchQueue.main.async {
//
//                if allowed {
//
//                }
//                else {
//
//                }
//            }
//        }
//    } catch {
//        print("could not start recording")
//    }
}
    
    @IBAction func PlayAction(_ sender: Any) {
        playAudioRecording(myUrl: audioFilename);
    }
    
    
//    @IBAction func start(_ sender: Any) {
//        print("The button was pressed")
//        if audioRecorder != nil && audioRecorder.isRecording {
//            audioRecorder.stop();
//            recordButton.setTitle("Tap to Record", for: .normal)
//            finishRecording(success: true)
//        }
//        else {
//            startRecording();
//        }
//    }
    
//    func startRecording() {
//        print("Recording started")
//        audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
//
//        let settings = [
//            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
//            AVSampleRateKey: 12000,
//            AVNumberOfChannelsKey: 1,
//            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
//        ]
//
//        do {
//            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
//            audioRecorder.delegate = self
//            audioRecorder.record()
//
//            recordButton.setTitle("Tap to Stop", for: .normal)
//        } catch {
//            finishRecording(success: false)
//        }
//    }

    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
//    func finishRecording(success: Bool) {
//        print ("finishRecording")
//        print(success)
//        audioRecorder.stop()
//        audioRecorder = nil
//        if success {
//            recordButton.setTitle("Tap to Re-record", for: .normal)
//        } else {
//            recordButton.setTitle("Tap to Record", for: .normal)
//            // recording failed :(
//        }
//    }
    
//    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
//        if !flag {
//            finishRecording(success: false)
//        }
//    }
    
    
    func playremote(urlstring : String) {
        let urlstring = "https://dementia.appspot.com/download/" + urlstring
        let url = URL(string: urlstring)
        
        print("playing \(url)")
        
        do {
            
            let playerItem = AVPlayerItem(url: url!)
            
            self.player = try AVPlayer(playerItem:playerItem)
            player!.volume = 1.0
            
            print("player.play()")
            print(player)
            player!.play()
            print("player.play() compelte")
        } catch {
            print("AVAudioPlayer init failed")
        }
    }
    
    func playAudioRecording2(url : URL) {
        print("playing \(url)")
        
        do {
            audioFromServer = try AVAudioPlayer(contentsOf: url)
            audioFromServer?.prepareToPlay()
            audioFromServer?.volume = 1.0
            audioFromServer?.play()
        } catch let error as NSError {
            //self.player = nil
            print("***Playing Failed")
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
        
    }
    
    func playAudioRecording(myUrl: URL)
    {
        print("playAudioRecording", myUrl )
        do{
            audioFromServer = try AVAudioPlayer(contentsOf: myUrl)
            audioFromServer?.play()
        }
        catch{
            print("could not load the file")
        }
        
    }
    

    func changeQuestion() {
        
        let jsonUrlString = "https://dementia.appspot.com/data/v1.0/getQuestion"
        
        guard let url = URL(string: jsonUrlString) else {return}
        
        URLSession.shared.dataTask(with: url) { (data, responds, err) in
            
            guard let data = data else{return}
            print("data", data)
            
            do{
                //print ("before parsing")
                let jsonParsedQuestion = try
                    JSONDecoder().decode(Question.self, from: data)
                //print ("reached code after try block")
                self.questionLabel.text = jsonParsedQuestion.text
                self.questionID = jsonParsedQuestion.id
                print (jsonParsedQuestion.type)
                print (jsonParsedQuestion.text)
                
//                self.downloadAndPlayAudio()
                self.playremote(urlstring: jsonParsedQuestion.speech!)
                
            }catch let jsonErr {
                print("Error serializing json: ", jsonErr)
            }
            
            }.resume()
    }
    
//    func downloadAndPlayAudio() {
//        let urlstring = "https://dementia.appspot.com/download/test.mp3"
//        let url = URL(string: urlstring)
//        print("the url = \(url!)")
//        self.downloadFileFromURL(url: url!)
//    }
    
    func downloadFileFromURL(url:URL){
        
        var downloadTask:URLSessionDownloadTask
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        downloadTask = session.downloadTask(with: url) { [weak self](url2, response, error) -> Void in
            
            self!.playAudioRecording2(url: url2!)
        }
        downloadTask.resume()
        
    }
    
    @IBAction func typeText(_ sender: Any) {
        textBox.isHidden = false
//        textBox.resignFirstResponder()
        textBox.becomeFirstResponder()
        
    }
    
 
    
    func enterTapped(){
        textAnswer = textBox.text
        
        if textAnswer != nil {
        let myPost = Answer(questionId: questionID, patientId:0,
                            answer: textAnswer)
            
            
        submitPost(post: myPost) { (error) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
         }
        }
        else{
        
            print("didn't submited text")}
        
    }
    
    
    func submitPost(post: Answer, completion:((Error?) -> Void)?) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "dementia.appspot.com"
        urlComponents.path = "/data/v1.0/storeAnswer"
        guard let url = urlComponents.url else { fatalError("Could not create URL from components") }
        
        // Specify this request as being a POST method
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // Make sure that we include headers specifying that our request's HTTP body
        // will be JSON encoded
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = "application/json"
        request.allHTTPHeaderFields = headers
        
        // Now let's encode out Post struct into JSON data...
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(post)
            // ... and set our request's HTTP body
            request.httpBody = jsonData
            print("jsonData: ", String(data: request.httpBody!, encoding: .utf8) ?? "no body data")
        } catch {
            completion?(error)
        }
        
        print ("do block")
        // Create and run a URLSession data task with our JSON encoded POST request
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            guard responseError == nil else {
                print("response error is not nil")
                completion?(responseError!)
                print("responseError")
                return
            }
            
            print ("URLSession")
            //let data = responseData
            // APIs usually respond with the data you just sent in your POST request
            //let utf8Representation = String(data: data, encoding: .utf8)
            //print("response: ", utf8Representation)
            
        }
        task.resume()
        textBox.text = ""
        changeQuestion()
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        textBox.resignFirstResponder()
    }




}


extension ViewController : UITextViewDelegate{
    
    func textViewShouldReturn( textView: UITextView)-> Bool{
        textView.resignFirstResponder()
        return true
    }
    
}


//TODO
// simple counter for questions (up to 6) send Done

