*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.Robocloud.Secrets
Library           RPA.Dialogs
#Library           XML

*** Variables ***
#${PDFSaveName}       ${EMPTY}    

*** Keywords ***
Open the robot order website
    ${website}=    Get Secret        navigateurl
    Log    ${website}
    Open Available Browser        ${website}[url]
    Click Button              OK
    Maximize Browser Window

*** Keywords ***
Get user input for order file
    Create Form    orders.csv URL
    Add Text Input    URL    url
    &{response}    Request Response
    [Return]    ${response["url"]}

*** Keywords ***
Download The CSV file
    ${csv_url}=        Get user input for order file
    Download        ${csv_url}        overwrite=True


*** Keywords ***
Fill And Submit The Form For One Order
    [Arguments]    ${order_det}
    Select From List By Value    id:head      ${order_det}[Head]
    #Select Radio Button    class:stacked   ${order_det}[Body]
    Click Element    id:id-body-${order_det}[Body]
    Input Text       class:form-control     ${order_det}[Legs]
    Input Text       id:address     ${order_det}[Address]
    Click Button    id:preview
    Wait Until Keyword Succeeds        6x        2 sec        Click Button     id:order  
    ${pdf}=         Store the receipt as a PDF file    ${order_det}[Order number]
    ${PngImage}=    Take a screenshot of the robot     ${order_det}[Order number]
    ${PDFItems}=    Create List          ${pdf}    ${PngImage}

    Add Files To Pdf        ${PDFItems}        ${CURDIR}${/}output${/}${order_det}[Order number]_final.pdf
    # Close Pdf       ${OrderPdf} 

    Wait Until Page Contains Element    order-another
    Click Button     id:order-another
    Click Button              OK  

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]        ${PDFSaveName}
    Wait Until Element Is Visible    id:receipt
    ${sales_results_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf_full_name}=     Set Variable    ${CURDIR}${/}output${/}${PDFSaveName}.pdf
    Html To Pdf    ${sales_results_html}    ${pdf_full_name}
    [Return]    ${pdf_full_name}

*** Keywords ***
Take a screenshot of the robot
    [Arguments]        ${ScreenshotSaveName}
    ${png_full_name}=     Set Variable    ${CURDIR}${/}output${/}${ScreenshotSaveName}.png
    Screenshot    id:robot-preview-image    ${png_full_name}
    [Return]    ${png_full_name}

*** Keywords ***
Fill The Form Using The Data From The CSV File
    #Open Workbook    orders.csv
    ${order_details}=    Read Table From Csv    orders.csv    header=True
    #Close Workbook
    FOR    ${order_det}    IN    @{order_details}
         Wait Until Keyword Succeeds        6x        2 sec        Fill And Submit The Form For One Order    ${order_det}    
         

    END
    Log    Running ${order_det}


*** Tasks ***
My Task
    Open the robot order website
    Download The CSV file
    [Teardown]    Fill The Form Using The Data From The CSV File
