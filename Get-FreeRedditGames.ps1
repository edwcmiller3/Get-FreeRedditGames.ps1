<#
.SYNOPSIS
    Get-FreeRedditGames: Get list of free games via reddit

.DESCRIPTION
    Scrape /r/GameDeals subreddit for free game deals and send [SMS/email] alert with download link.

.PARAMETER Alert
    Switch parameter to set if script should send alerts. Default is $False and sends output to text file.

.EXAMPLE
    Basic function call. Scrapes subreddit for free games and sends output to a text file.
    Get-FreeRedditGames

.EXAMPLE
    Function call using Alert switch. Scrapes subreddit for free games and sends alert to user defined in script.
    Get-FreeRedditGames -Alert

.INPUTS
    None

.OUTPUTS
    None

.NOTES
    Version:        1.2
    Author:         Edward C Miller III
    Creation Date:  12-04-2014
    Purpose/Change: Changed credential management with Clixml
    TODO: Fix credential management
#>

Function Get-FreeRedditGames {

    [CmdletBinding()]
    Param(
        [Switch]$Alert = $False
    )

    Begin {
        Try {
            #Collect array of only submission links from GameDeals/new/
            $GameDeals = (Invoke-WebRequest -Uri "http://www.reddit.com/r/GameDeals/new/" -ErrorAction Stop).Links `
                | Where-Object { $_.class -like "*title*" }
        }
        Catch {
            Write-Error -Message "Error retrieving links."
            $_.Exception.Message | Out-File .\Get-FreeRedditGamesErrors.txt -Append
        }

        #Create credential object for PowerShellEmailBot email account
        $Cred = Import-Clixml .\PowerShellEmailBot.xml

        #Create empty hash tables for organizing free game deals & all game deals
        $HashFreeDeals = @{}

        #Get free game deals excluding titles like "DRM-free" and "free shipping"
        $FreeDeals = $GameDeals.Where({ (("free" -in $_.outerText.ToString().Split()) -or ("(free)" -in $_.outerText.ToString().Split())) `
                                -and ("shipping" -notin $_.outerText.ToString().Split()) })
        #Regex needs work
        #[System.Text.RegularExpressions.Regex]::Replace("(free)", "[()]", "")
        
        #Add results to hash table
        $FreeDeals | ForEach-Object { $HashFreeDeals[$_.outerText] = $_.href }

        #Avoid "Collection was modified; enumeration operation may not execute" error
        #Loop over clone, make changes to original
        $HashFreeDealsClone = $HashFreeDeals.Clone()

        #Read previously scraped deals from log file
        $OldDeals = Get-Content .\OldFreeRedditGamesDeals.txt
    }

    Process {
        #Check $OldDeals (OldFreeRedditGameDeals.txt) for duplicates and remove from $HashFreeDeals
        #Only alert and append new deals to file this way
        foreach ($Key in $HashFreeDealsClone.Keys) {
            If ($Key -in $OldDeals) {
                $HashFreeDeals.Remove($Key)
            }
        }

        #If Alert switch used, send an email alert
        If ($Alert -and $HashFreeDeals.Count) {
            $From = "ScriptEmail@something.com"
            $To = "YourEmailOrPhoneNumber@something.com"
            $Subject = "Free Reddit Game Script Alert"
            $Body = ($HashFreeDeals.Keys | ForEach-Object {
                "$_`r`n$($HashFreeDeals[$_])"
                } ) -join "`r`n`n"
            $SMTPServer = "smtp.email.com"
            $SMTPPort = "###"
            Try {
                #Attempt to send mail alert with deals
                Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -UseSsl -Credential $Cred
            }
            Catch {
                #Could not send message
                Write-Error -Message "Error sending message. See error log file."
                $_.Exception.Message | Out-File .\Get-FreeRedditGamesErrors.txt -Append
            }
        }
    }
   

    End {
        #Append free game deals to OldFreeRedditGamesDeals.txt log
        #ForEach-Object gets the Key, carriage return & newline, Value, then joins each object with a carriage return and 2 newlines
        If ($HashFreeDeals.Count) {
            #Time stamping
            "[Run at: " + (Get-Date).DateTime + ']' | Out-File .\OldFreeRedditGamesDeals.txt -Append

            ($HashFreeDeals.Keys | ForEach-Object { "$_`r`n$($HashFreeDeals[$_])" }) -join "`r`n`n" `
                | Out-File .\OldFreeRedditGamesDeals.txt -Append
        }
    }

}
