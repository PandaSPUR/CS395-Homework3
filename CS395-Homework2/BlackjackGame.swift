//
//  BlackjackModel.swift
//  CS395-Homework1
//
//  Created by Pan Chan on 9/21/14.
//

import Foundation

struct Card {
    var suit: Int
    var suitString: String
    var value: Int
    var valueString: String
}

class Shoe {
    var decks = 1
    var deck = [Card]()
    
    func shuffleDeck() {
        deck = [Card]()
        for n in 0..<decks {
            for i in 0..<4{
                var suitStrings = ["Diamonds", "Clubs", "Hearts", "Spades"]
                var valueStrings = ["Ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King"]
                var tempValue: Int
                for j in 1...13 {
                    tempValue = j
                    if tempValue > 10 {
                        tempValue = 10
                    }
                    deck.append(Card(suit: i, suitString: suitStrings[i], value: tempValue, valueString: valueStrings[j-1]))
                }
            }
        }
    }
    
    func getCard() -> Card {
        //var randomCard = Int(rand()) % (deck.count - 1)
        var randomCard = Int(arc4random_uniform(UInt32(deck.count)))
        var cardOut = deck.removeAtIndex(randomCard)
        return cardOut
    }
}

class Player {
    //Array of array to account for future need for "Splitting" a hand.
    var hands = [[Card]]()
    var handValues = [[Int]]()
    
    var bank = 100.00
    var bet = 0.00
    
    /*
    Player status flag. Helps with displaying status on GUI
    0 = Round Start: Waiting for bet/deal
    1 = New Hand: player has not lost/won yet. Enable hit/stay, disable bet/deal.
    2 = Stay: player is staying, has not lost/won yet. Disable all options.
    3 = Win: Disable hit/stay, enable bet/deal. Check if blackjack. Give winnings
    4 = Lose: Disable hit/stay, enable bet/deal. Take bet
    5= Push: Disable hit/stay, enable bet/deal. No change to bank
    6 = Game over: player broke. Disable hit/stay, enable new game.
    */
    var playerStatus = 0
    var blackjack = false
    
    func bet(newBet: Double) {
        if playerStatus != 0 {
            return
        }
        if newBet > 0.0 && newBet < bank {
            bet = newBet
        }
    }
    
    func deal(gameShoe: Shoe) {
        if playerStatus != 0 || bet < 1{
            return
        }
        playerStatus = 1
        hands.append([Card]())
        handValues.append([Int]())
        handValues[0].append(0)
        
        var newCard: Card
        for i in 0..<2 {
            newCard = gameShoe.getCard()
            hands[0].append(newCard)
            
            //Add value of the current card to all possible total card values of current hand
            for i in 0..<handValues[0].count {
                handValues[0][i] = handValues[0][i] + newCard.value
            }
            
            //if newCard is Ace.
            if newCard.value == 1 {
                var nHandValues = handValues[0].count
                for i in 0..<nHandValues {
                    handValues[0].append(handValues[0][i] + 11)
                }
            }
        }
        
        //Check for 21
        for i in 0..<handValues[0].count {
            if handValues[0][i] == 21 {
                blackjack = true
                stay()
            }
        }
    }
    
    func hit(gameShoe: Shoe) {
        if playerStatus != 1 {
            return
        }
        var newCard: Card
        newCard = gameShoe.getCard()
        hands[0].append(newCard)
        for i in 0..<handValues[0].count {
            handValues[0][i] = handValues[0][i] + newCard.value
        }
        
        //if newCard is Ace.
        if newCard.value == 1 {
            var nHandValues = handValues[0].count
            for i in 0..<nHandValues {
                handValues[0].append(handValues[0][i] + 11)
            }
        }
        
        //Check for 21
//        for i in 0..<handValues[0].count {
//            if handValues[0][i] == 21 {
//                stay()
//            }
//        }
        
        //Clean up busted hand values
        for var i = handValues[0].count; i > 0; --i {
            if handValues[0][i-1] > 21 {
                    handValues[0].removeAtIndex(i-1)
            }
        }
        
        //If player busted completely, he loses.
        if handValues[0].count == 0{
            playerStatus = 4
        }
    }
    
    func stay() {
        playerStatus = 2
        
        //Make things easier in the end, put the highest possible combination of cards at index 0.
        //So if player stayed with Ace and Nine, 20 would be stored at [0] and not 10.
        var maxValue = handValues[0][0]
        for i in 0..<handValues[0].count {
            if handValues[0][i] > maxValue {
                maxValue = handValues[0][i]
            }
        }
    }
    
    func endRound() {
        switch playerStatus {
        case 3: //win
            if blackjack {
                bank += (bet * 1.5)
            }
            else {
                bank += bet
            }
        case 4: //lose
            bank -= bet
            if bank <= 0 {
                playerStatus = 6
            }
        case 5: //push
            return
        default:
            return
        }
    }
    
    func newRound() {
        if playerStatus > 2 && playerStatus < 6 {
            blackjack = false
            bet = 0
            playerStatus = 0
            hands = [[Card]]()
            handValues = [[Int]]()
        }
    }
}

class Dealer {
    //Array of array to account for future need for "Splitting" a hand.
    var hands = [[Card]]()
    var handValues = [[Int]]()
    
    /*
    Dealer status flag. Helps with displaying status on GUI
    0 = Round Start: dealer waiting
    1 = Dealer dealt: dealer has 2 cards and is waiting
    2 = Dealer stay: all players finished, dealer is finished, evaluate all scores now.
    3 = Dealer bust: any players still in win.
    */
    var dealerStatus = 0
    var blackjack = false
    
    func deal(gameShoe: Shoe) {
        if dealerStatus != 0 {
            return
        }
        dealerStatus = 1
        hands.append([Card]())
        handValues.append([Int]())
        handValues[0].append(0)
        
        var newCard: Card
        for i in 0..<2 {
            newCard = gameShoe.getCard()
            hands[0].append(newCard)
            
            //Add value of the current card to all possible total card values of current hand
            for i in 0..<handValues[0].count {
                handValues[0][i] = handValues[0][i] + newCard.value
            }
            
            //if newCard is Ace.
            if newCard.value == 1 {
                var nHandValues = handValues[0].count
                for i in 0..<nHandValues {
                    handValues[0].append(handValues[0][i] + 11)
                }
            }
        }
        
        //Check for 21
        for i in 0..<handValues[0].count {
            if handValues[0][i] == 21 {
                blackjack = true
                stay()
            }
        }
    }
    
    func hit(gameShoe: Shoe) {
        //If dealer is already higher than 16, dont hit.
        for i in 0..<handValues[0].count {
            if handValues[0][i] > 16 {
                stay()
            }
        }
        
        //Otherwise, we give dealer one card
        var newCard: Card
        newCard = gameShoe.getCard()
        hands[0].append(newCard)
        for i in 0..<handValues[0].count {
            handValues[0][i] = handValues[0][i] + newCard.value
        }
        
        //if newCard is Ace.
        if newCard.value == 1 {
            var nHandValues = handValues[0].count
            for i in 0..<nHandValues {
                handValues[0].append(handValues[0][i] + 11)
            }
        }
        
        //Clean up busted hand values
        for var i = handValues[0].count; i > 0; --i {
            if handValues[0][i-1] > 21 {
                handValues[0].removeAtIndex(i-1)
            }
        }
        
        //If dealer busted, he loses.
        if handValues[0].count == 0{
            dealerStatus = 3
        }
        
        //Dealer only hits once if at all.
        stay()
    }
    
    func stay() {
        if dealerStatus == 3 {
            return
        }
        dealerStatus = 2
        
        //Make things easier in the end, put the highest possible combination of cards at index 0.
        //So if player stayed with Ace and Nine, 20 would be stored at [0] and not 10.
        var maxValue = handValues[0][0]
        for i in 0..<handValues[0].count {
            if handValues[0][i] > maxValue {
                maxValue = handValues[0][i]
            }
        }
    }
    
    func newRound() {
        dealerStatus = 0
        blackjack = false
        hands = [[Card]]()
        handValues = [[Int]]()
    }
}