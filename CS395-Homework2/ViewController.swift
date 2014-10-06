//
//  ViewController.swift
//  CS395-Homework1
//
//  Created by Panda on 9/21/14.
//  Copyright (c) 2014 Panda. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var playerStatusLabel: UILabel!
    @IBOutlet var cashLabel: UILabel!
    @IBOutlet var playerCardsLabel: UILabel!
    @IBOutlet var dealerCardsLabel: UILabel!
    @IBOutlet var currentPlayerLabel: UILabel!
    
    @IBOutlet var stayButton: UIButton!
    @IBOutlet var hitButton: UIButton!
    @IBOutlet var startButton: UIButton!
    @IBOutlet var addPlayerButton: UIButton!
    
    @IBOutlet var betLabel: UILabel!
    @IBOutlet var betStepper: UIStepper!
    
    @IBOutlet var swipeRight: UISwipeGestureRecognizer!
    @IBOutlet var swipeLeft: UISwipeGestureRecognizer!
    
    
    
    var shoe = Shoe()
    var players = [Player]()
    var dealer = Dealer()
    
    var playerView = 0
    /*
    Game status flag.
    0 = Round Start: Waiting for all players to bet.
    1 = Hands Dealt: Waiting for all players to hit/stay/bust
    2 = Stay: player is staying, has not lost/won yet. Disable all options.
    3 = Win: Disable hit/stay, enable bet/deal.
    4 = Lose: Disable hit/stay, enable bet/deal.
    5 = Game over: player broke. Disable hit/stay, enable new game.
    */
    var gameStatus = 0
    
    var gamesPlayed = 0
    
    func updateUI() {
        if playerView == players.count {
            addPlayerButton.hidden = false
            addPlayerButton.enabled = true
            
            playerStatusLabel.hidden = true
            cashLabel.hidden = true
            playerCardsLabel.hidden = true
            stayButton.hidden = true
            hitButton.hidden = true
            betLabel.hidden = true
            betStepper.hidden = true
        }
        else {
            addPlayerButton.hidden = true
            addPlayerButton.enabled = false
            
            playerStatusLabel.hidden = false
            cashLabel.hidden = false
            playerCardsLabel.hidden = false
            stayButton.hidden = false
            hitButton.hidden = false
            betLabel.hidden = false
            betStepper.hidden = false
            
            currentPlayerLabel.text = "Player \(playerView + 1)"
            
            //Player Info: Always shown
            var playerCardsString = ""
            if players[playerView].playerStatus > 0 {
                for var i = 0; i < players[playerView].hands[0].count; ++i {
                    playerCardsString += "\(players[playerView].hands[0][i].valueString) of \(players[playerView].hands[0][i].suitString)\n"
                }
            }
            playerCardsLabel.text = playerCardsString
            cashLabel.text = "Cash: $\(players[playerView].bank)"
            if players[playerView].bet != 0 {
                betLabel.text = "$\(players[playerView].bet)"
                betStepper.enabled = false
            }
            
            //Player Info: Based on playerStatus
            switch players[playerView].playerStatus {
            case 0: //waiting for bet/deal
                playerStatusLabel.text = "Waiting for all players to place bets"
                stayButton.enabled = false
                hitButton.enabled = false
                betLabel.enabled = true
                betLabel.text = ""
            case 1: //bet placed, hand dealt
                playerStatusLabel.text = "Hit or Stay?"
                stayButton.enabled = true
                hitButton.enabled = true
                betLabel.enabled = false
                betLabel.text = "Bet: $\(players[playerView].bet)"
            case 2: //staying
                playerStatusLabel.text = "Waiting for other players"
                stayButton.enabled = false
                hitButton.enabled = false
                betLabel.enabled = false
                betLabel.text = "Bet: $\(players[playerView].bet)"
            case 3: //won
                stayButton.enabled = false
                hitButton.enabled = false
                betLabel.enabled = false
                if players[playerView].blackjack {
                    playerStatusLabel.text = "Blackjack!"
                    betLabel.text = "Won $\(players[playerView].bet * 1.5)"
                }
                else {
                    playerStatusLabel.text = "You won!"
                    betLabel.text = "Won $\(players[playerView].bet)"
                }
            case 4: //lose
                playerStatusLabel.text = "You lose."
                stayButton.enabled = false
                hitButton.enabled = false
                betLabel.enabled = false
                betLabel.text = "Lost $\(players[playerView].bet)"
            case 5: //push
                playerStatusLabel.text = "Push."
                stayButton.enabled = false
                hitButton.enabled = false
                betLabel.enabled = false
                betLabel.text = " "
            case 6: //broke
                playerStatusLabel.text = "You're broke!"
                stayButton.enabled = false
                hitButton.enabled = false
                betLabel.enabled = false
                betLabel.text = " "
            default:
                break
            }
            
            switch dealer.dealerStatus {
            case 0: //waiting for players to bet
                startButton.enabled = false
                dealerCardsLabel.text = ""
            case 1:
                startButton.enabled = false
                dealerCardsLabel.text = "\(dealer.hands[0][0].valueString) of \(dealer.hands[0][0].suitString)"
                
            case 2, 3:
                startButton.enabled = true
                startButton.setTitle("Start New Round", forState: UIControlState.Normal)
                
                var dealerCardsString = ""
                for var i = 0; i < dealer.hands[0].count; ++i {
                    dealerCardsString += "\(dealer.hands[0][i].valueString) of \(dealer.hands[0][i].suitString)\n"
                }
                dealerCardsLabel.text = dealerCardsString
            default:
                break
            }
        }
    }
    
    func updateGame() {
        switch dealer.dealerStatus {
        case 0: //Dealer waiting for players to make their bets.
            if gamesPlayed >= 5 {
                shoe.shuffleDeck()
            }
            
            var playersReady = true
            for i in 0..<players.count {
                if players[i].bet == 0 && players[i].playerStatus == 0 {
                    playersReady = false
                    break
                }
            }
            if playersReady {
                for i in 0..<players.count {
                    players[i].deal(shoe)
                }
                dealer.deal(shoe)
                gamesPlayed+=1
            }
        case 1: //Cards are dealt, Dealer waiting for players to finish.
            var playersReady = true
            for i in 0..<players.count {
                if players[i].playerStatus < 2 {
                    playersReady = false
                    break
                }
            }
            if playersReady {
                dealer.hit(shoe)
                updateGame()
            }
        case 2: //Dealer hit/stay
            for i in 0..<players.count {
                if players[i].playerStatus == 2 {
                    if dealer.blackjack {
                        if players[i].blackjack {
                            players[i].playerStatus = 5 //push
                        }
                        else {
                            players[i].playerStatus = 4 //lose
                        }
                    }
                    else {
                        if players[i].handValues[0][0] > dealer.handValues[0][0] {
                            players[i].playerStatus = 3 //win
                        }
                        else if players[i].handValues[0][0] < dealer.handValues[0][0] {
                            players[i].playerStatus = 4 //lose
                        }
                        else {
                            players[i].playerStatus = 5 //push
                        }
                    }
                }
                players[i].endRound()
            }
        case 3: //Dealer busts
            for i in 0..<players.count {
                if players[i].playerStatus == 2 {
                    players[i].playerStatus = 3 //win
                }
            }
        default:
            break
        }
        updateUI()
    }
    
    @IBAction func betChanged(sender: AnyObject) {
        betLabel.text = Int(betStepper.value).description
    }
    
    @IBAction func betPlaced(sender: AnyObject) {
        players[playerView].bet(Double(betStepper.value))
        updateGame()
    }
    
    @IBAction func startTapped(sender: AnyObject) {
        for i in 0..<players.count {
            players[i].newRound()
        }
        dealer.newRound()
        updateGame()
    }
    
    @IBAction func hitTapped(sender: AnyObject) {
        players[playerView].hit(shoe)
        updateGame()
        updateUI()
    }
    
    @IBAction func stayTapped(sender: AnyObject) {
        players[playerView].stay()
        updateGame()
    }
    
    //Previous player
    @IBAction func swipedRight(sender: AnyObject) {
        playerView--
        if playerView < 0 {
            playerView = 0
        }
        updateUI()
    }
    
    //Next player
    @IBAction func swipedLeft(sender: AnyObject) {
        playerView++
        if playerView > players.count {
            playerView = players.count
        }
        updateUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        playerCardsLabel.numberOfLines = 0 //0 = infinite number of lines
        dealerCardsLabel.numberOfLines = 0
        
        //setup the default 3 players
        shoe.decks = 3
        shoe.shuffleDeck()
        players.append(Player())
        players.append(Player())
        
        updateGame()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

