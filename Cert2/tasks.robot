*** Settings ***
Documentation    Orders robots from RobotSpareBin Industries Inc.
...              Saves the order HTML receipt as a PDF file.
...              Saves the screenshot of the ordered robot.
...              Embeds the screenshot of the robot to the PDF receipt.
...              Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.FileSystem
Library           RPA.PDF
Library           RPA.Desktop
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault


*** Keywords ***
Open Website
    Open Available Browser         https://robotsparebinindustries.com/#/robot-order

*** Keywords ***
Click Okay
    Click Button    OK

*** Keywords ***
Get user's name
    Add text input          MyName    label=What is your name?     placeholder=Name here
    ${result}=              Run dialog
    [Return]                ${result.MyName}

*** Keywords ***
Get Orders
    Download    https://robotsparebinindustries.com/orders.csv      overwrite=True
    ${orders}=  Read table from CSV    orders.csv      header=true
    [Return]   ${orders}

*** Keywords ***
Fill Order
    [Arguments]   ${orders}
    Select From List By Value       head       ${orders}[Head]
    Click Element When Visible      id:id-body-${orders}[Body]  
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${orders}[Legs] 
    Input Text    address    ${orders}[Address] 

*** Keywords ***
Preview Robot
    Wait and Click Button        id:preview

*** Keywords ***
Submit Order
    Wait And Click Button          id:order  
    Page Should Contain            Receipt     

*** Keywords ***
Order Another
    Click Button           id:order-another 

*** Keywords ***
Store receipt as a PDF
    [Arguments]   ${orders}
    ${pdf}=     Get Element Attribute    id:receipt    outerHTML 
    Html To Pdf    ${pdf}    ${OUTPUT_DIR}${/}receipt_${orders}.pdf
    #Html To Pdf    ${pdf}    ${OUTPUT_DIR}${/}receipt_${orders}[Order number].pdf
    [Return]  ${OUTPUT_DIR}${/}receipt_${orders}.pdf

*** Keywords ***
Take a screenshot of Robot
    [Arguments]    ${orders}
    Page Should Contain Element     id:robot-preview-image
    ${screenshot}=    Screenshot      id:robot-preview-image     ${OUTPUT_DIR}${/}receipt_${orders}.png
    #${screenshot}=    Screenshot      id:robot-preview-image     ${OUTPUT_DIR}${/}receipt_${row}[Order number].jpg 
    [Return]  ${OUTPUT_DIR}${/}receipt_${orders}.png

*** Keywords ***
Embed Screenshot in PDF
    [Arguments]   ${screenshot}  ${pdf}   ${orders}
    Open Pdf    ${pdf}
    ${mylist}=      Create List     ${screenshot}
    Add Files To Pdf    ${mylist}   ${pdf}
    Close Pdf     ${pdf}

*** Keywords ***
Create a ZIP file of the receipts
    [Arguments]    ${pdf}
    Archive Folder With Zip    ${OUTPUT_DIR}    ${OUTPUT_DIR}${/}receipts.zip

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc.
    ${username}=  Get user's name
    Open Website
    Click Okay
   ${orders}=  Get Orders
        FOR    ${row}    IN    @{orders}  
        Fill Order         ${row}
        Preview Robot
        Wait Until Keyword Succeeds    5x   0.5sec    Submit Order
        ${pdf}=  Store receipt as a PDF    ${row}[Order number] 
        ${screenshot}=  Take a screenshot of Robot    ${row}[Order number]
        Embed Screenshot in PDF     ${pdf}     ${screenshot}  ${orders} 
        Order Another
        Click Okay   
    END
        Create a ZIP file of the receipts       ${pdf}

