<#
.Synopsis
   Initiates a new game of Wordle4PS. This is a just-for-fun powershell take on the game Wordle, created by Josh Wardle.
   See here for the original game: https://www.powerlanguage.co.uk/wordle/
   A word will be selected randomly from a text file containing 12k 5 letter words
.DESCRIPTION
   Will launch a new game of Wordle4PS, with the specified number of guesses allowed.
.EXAMPLE
   New-WordleGame -GuessLimit 6
.NOTES
    Bryce Carter - iambryce@gmail.com
#>
function New-WordleGame
{
    Param
    (
        [ValidateNotNullOrEmpty()]
        $GuessLimit = 6
    )

    #region Setup

    cls

    Write-Host -ForegroundColor Cyan "Beginning a new round of Wordle4PS with $GuessLimit turns!"
    
    Write-Host ""
    Write-Host "Green = Correct letter with correct placement" -ForegroundColor Green -BackgroundColor DarkGray
    Write-Host "Yellow = Correct letter with incorrect placement" -ForegroundColor Yellow -BackgroundColor DarkGray
    Write-Host "Gray = Incorrect letter" -ForegroundColor Gray -BackgroundColor DarkGray
    Write-Host ""

    $Words = Get-Content -Path "$PSScriptRoot\words\5LetterWords.txt"

    $LetterCount = 5
    $GuessedCorrectly = $false

    $TargetWord = Get-Random $Words
    $TargetWord = $TargetWord -replace '[^a-zA-Z]'
    $TargetWord = $TargetWord.ToUpper()
    $TargetWordArray = $TargetWord.toCharArray()

    Write-Host "Target word retrieved. Good luck!"

    #This arraylist will contain all of the letters that have been guessed this round, de-duped
    $AllGuessedChars = New-Object -TypeName 'System.Collections.ArrayList'

    #This arraylist will contain all of the letters that have not been guessed yet this round
    $AllRemainingUnguessedChars = New-Object -TypeName 'System.Collections.ArrayList'
    65..90 | foreach-object{ $AllRemainingUnguessedChars.Add([char]$_ ) | out-null }

    #endregion Setup
    
    #region Main Game Loop

    Write-Host -ForegroundColor Cyan "---"

    #loop until we have reached the guess limit, or until the correct word is guessed
    $i = 1
    while (($i -le $GuessLimit) -and (-not $GuessedCorrectly))
    {

        #start by retrieving and validating the user's guess word
        $GuessWord = $null

        while(-not $GuessWord)
        {
            $GuessWord = Read-Host "Enter guess $i"

            #Clean up anything from input that isn't an alpha character
            $GuessWord = $GuessWord -replace '[^a-zA-Z]'
            $GuessWord = $GuessWord.ToUpper()

            #is the word that was guessed the correct amount of letters?
            if($GuessWord.Length -ne $LetterCount)
            {
                Write-Host -ForegroundColor Yellow "The word you guessed is not the correct amount of letters. Try again!"
                $GuessWord = $null
                Continue
            }

            #is the word that was guessed a valid word from the dictionary of available words?
            if($Words -inotcontains $GuessWord)
            {
                Write-Host -ForegroundColor Yellow "The word you guessed is not in the list of available words. Try again!"
                $GuessWord = $null
                Continue
            }
        }

        
        if($GuessWord -eq $TargetWord)
        {
            $GuessedCorrectly = $true
            Continue
        }

        #They did not guess the correct word. Increment the guess counter and move on with comparison logic
        $i++

        #Now we have a valid guess word. Time to compare against the Target Word

        $GuessWordArray = $GuessWord.tochararray()

        $ResultArray = New-Object int[] $TargetWordArray.length
        #ResultArray will contain:
        #1 for correct matches in correct location
        #2 for correct match in incorrect location
        #0 for incorrect match

        $RemainingUnmatchedChars = New-Object -TypeName 'System.Collections.ArrayList'
            
        #loop to check for correct matches in correct location
        for ($j = 0; $j -lt $GuessWordArray.length; $j++)
        { 
                
            #add this char to the list of all chars guessed, if it's not there already
            if($AllGuessedChars -notcontains $GuessWordArray[$j])
            {
                $AllGuessedChars.Add($GuessWordArray[$j]) | Out-Null
            }

            if($GuessWordArray[$j] -eq $TargetWordArray[$j])
            {
                #this letter is a match, and in the correct location
                #mark it as a 1 in the result array
                $ResultArray[$j] = 1
            }
            else
            {
                #this letter is not a match in the correct location
                #mark it as a 0 in the result array
                $ResultArray[$j] = 0

                #add this char to the array of chars in the target word that haven't been matched yet
                $RemainingUnmatchedChars.Add($TargetWordArray[$j]) | Out-Null
            }
        }


        #Now we know which characters were guessed correctly, in the correct location. 
        #Next we need to find characters that were guessed correct, but wrong location.


        #loop to check for correct matches in incorrect location
        for ($j = 0; $j -lt $GuessWordArray.length; $j++)
        { 
            if($ResultArray[$j] -eq 1)
            {
                #this guessed character is already confirmed correct, and in the correct location. skip it so we don't double-match it
                Continue
            }

            if($RemainingUnmatchedChars -contains $GuessWordArray[$j])
            {
                #this is a guessed character that is correct, but in wrong location
                #mark it as a 2 in the result array
                $ResultArray[$j] = 2

                #remove this character from the RemainingUnmatchedChars so it doesn't get double-matched
                $RemainingUnmatchedChars.Remove($GuessWordArray[$j])
            }
        }


        #Write the results out with color coding
        for ($j = 0; $j -lt $ResultArray.Length; $j++)
        { 
            switch ($ResultArray[$j])
            {
                0 { Write-Host $GuessWordArray[$j] -ForegroundColor Gray -BackgroundColor DarkGray -NoNewline }
                1 { Write-Host $GuessWordArray[$j] -ForegroundColor Green -BackgroundColor DarkGray -NoNewline }
                2 { Write-Host $GuessWordArray[$j] -ForegroundColor Yellow -BackgroundColor DarkGray -NoNewline }
            }
        }

        
        foreach($char in $AllGuessedChars)
        {
            if($AllRemainingUnguessedChars -contains $char)
            {
                $AllRemainingUnguessedChars.Remove($char) 
            }
        }

        Write-Host ""
        Write-Host -ForegroundColor Gray "Letters guessed so far:" $AllGuessedChars
        Write-Host -ForegroundColor Gray "Letters that have NOT been guessed yet:" $AllRemainingUnguessedChars | Where-Object {$AllGuessedChars -notcontains $_ }
        Write-Host -ForegroundColor Cyan "---"

    } # END while (($i -le $GuessLimit) -and (-not $GuessedCorrectly))

    #endregion Main Game Loop


    if($GuessedCorrectly)
    {
        Write-Host -ForegroundColor Green "Congratulations, you win! The word was $TargetWord. You guessed it in $i / $GuessLimit turns."
    }
    else
    {
        Write-Host -ForegroundColor Yellow "Sorry, you lose! The word was $TargetWord"
    }

}# end function New-WordleGame


$playAgain = "y"

$host.ui.RawUI.WindowTitle = $MyInvocation.MyCommand.Name -replace ('.ps1','')

while($playAgain -ilike "y*")
{
    New-WordleGame
    
    $playAgain = read-host "Do you want to play again? (Y / N)"
}