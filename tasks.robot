*** Settings ***
Documentation     Asks user for value as a receipt reference
...               Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshots of the ordered robot.
...               Embeds the screenshots of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images using the reference.
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.FileSystem
Library    RPA.Dialogs
Library    RPA.Robocorp.Vault
Library    RPA.Desktop

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${ref}=    Get reference from user
    Create output directories
    ${orders}=    Get orders
    Open the robot order website
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts    ${ref}
    [Teardown]    Delete output directories and close browser

*** Keywords ***
Create output directories
    Create Directory    ${OUTPUT_DIR}${/}receipts
    Create Directory    ${OUTPUT_DIR}${/}robots
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
Get orders
    Log    GET SECRET
    ${secret}=    Get Secret    credentials
    Log    SECRET GET
    Download    ${secret}[link]    overwrite=True
    ${CSV}=    Read table from CSV    orders.csv
    Return From Keyword    ${CSV}
Close the annoying modal
    Click Button    //button[@class="btn btn-dark"]
Fill the form
    [Arguments]    ${row}
    Select From List By Index    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    //input[@class="form-control"][@type="number"]    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
Preview the robot
    Click Button    id:preview
Submit the order
    Wait Until Element Is Visible    id:robot-preview
    Click Button    id:order
Store the receipt as a PDF file
    [Arguments]    ${Order_number}
    ${err}=    Check for error
    IF    ${err} == ${TRUE}
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${Order_number}
        Return From Keyword    ${pdf}
    ELSE
        Wait Until Element Is Visible    id:receipt
        ${sales_results_html}=    Get Element Attribute    id:receipt    outerHTML
        Html To Pdf    ${sales_results_html}    ${OUTPUT_DIR}${/}receipts${/}receipt-${Order_number}.pdf
        Return From Keyword    ${OUTPUT_DIR}${/}receipts${/}receipt-${Order_number}.pdf
    END
Take a screenshot of the robot
    [Arguments]    ${Order_number}
    Wait Until Element Is Visible    //div[@id="robot-preview-image"]/img[@alt="Head"]
    Wait Until Element Is Visible    //div[@id="robot-preview-image"]/img[@alt="Body"]
    Wait Until Element Is Visible    //div[@id="robot-preview-image"]/img[@alt="Legs"]
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robots${/}robot-${Order_number}.png
    Return From Keyword    ${OUTPUT_DIR}${/}robots${/}robot-${Order_number}.png
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${ss}    ${pdf}
    Open Pdf    ${pdf}
    ${files}=    Create List    ${ss}:align=center
    Add Files To Pdf    ${files}    ${pdf}    ${TRUE}
    Close Pdf
Go to order another robot
    Click Button    id:order-another
Create a ZIP file of the receipts
    [Arguments]    ${ref}
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}receipts-${ref}.zip
Check for error
    ${err}=    Does Page Contain Element    //div[@class="alert alert-danger"]
    Return From Keyword    ${err}
Delete output directories and close browser
    Remove File    orders.csv
    Remove Directory    ${OUTPUT_DIR}${/}receipts    recursive=${TRUE}
    Remove Directory    ${OUTPUT_DIR}${/}robots    recursive=${TRUE}
    Close Browser
Get reference from user
    Add heading     Please enter a reference for your receipt
    Add text input  name=ref
    ${result}=      Run dialog
    Return From Keyword    ${result.ref}