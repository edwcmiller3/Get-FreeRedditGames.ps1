# Get-FreeRedditGames.ps1
PowerShell script designed to scrape reddit.com/r/gamedeals for posts with games marked as "free" in the title, then send an alert with a link to the deal via email. 

-Logs errors retreiving website to a file (Get-FreeRedditGamesErrors.txt).
-Logs old deals to a file (OldFreeRedditGamesDeals.txt) to prevent duplicate alerts.
-Currently requires creating a credential file that is imported via Import-Climxl for sending the alert email. Can be modified to accept credentials manually during run via switch and Get-Credentials.
