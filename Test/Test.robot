*** Settings ***
Library    SeleniumLibrary
Library    ../Libraries/Users.py
Library    ../venv/lib/python3.12/site-packages/robot/libraries/Collections.py
Variables    ../Variables/variable.py

Suite Setup    Launch Browser    https://marmelab.com/react-admin-demo/#/login
Suite Teardown    Close Browser

*** Variables ***
${USERS}
${CUSTOMERS}

*** Test Cases ***

Test Case 1
    Fetch Data
    Login User    demo    demo
    Add Users Loop
    Get All Users
    Log New And Existing User
    Sleep    20s

Test Case 2
    # Fetch Data
    # Login User    demo    demo
    # Go To Link    customers
    # Wait Until Element Is Visible    xpath=//table/tbody/tr    10s
    # Get All Users
    Count Customer Orders

    
*** Keywords ***

Launch Browser
    [Arguments]    ${url}=https://www.google.com/
    ${options}    Set Variable    add_argument("--start maximized")
    Open Browser    ${url}    chrome    remote_url=http://172.17.0.1:4444    options=${options}

Login User
    [Arguments]    ${username}    ${password}
    Input Text    name=username    ${username}
    Input Text    name=password    ${password}
    Click Button    css=button[type='submit']

Go To Link
    [Arguments]    ${link}
    Click Element    xpath=//a[contains(@href, '#/${link}')]

Fetch Data
    ${users}    Get Users Via Api
    Set Suite Variable    ${USERS}    ${users}

Add Users Loop
    FOR    ${user}    IN    @{USERS}
        Go To Link    customers
        Wait Until Element Is Visible    xpath=//a[@aria-label='Create']    10s
        Open Identity Modal
        Add User Data To Identity    ${user}
        Wait Until Page Contains    Delete    10s
    END
    Go To Link    customers

Add User Data To Identity
    [Arguments]    ${user}
    ${first_name}    Evaluate    " ".join("${user['name']}".split()[:-1]).strip()
    ${last_name}    Evaluate    " ".join("${user['name']}".split()[-1:]).strip()
    Input Text    xpath=//input[@name='first_name']    ${first_name}
    Input Text    xpath=//input[@name='last_name']    ${last_name}
    Input Text    xpath=//input[@name='email']    ${user['email']}
    Input Date    xpath=//input[@name='birthday']    ${user['birthday']}
    Input Text    xpath=//textarea[@name='address']    ${user['address']['street']}
    Input Text    xpath=//input[@name='city']    ${user['address']['city']}
    Input Text    xpath=//input[@name='stateAbbr']    ${user['address']['state']}
    Input Text    xpath=//input[@name='zipcode']    ${user['address']['zipcode']}
    Input Text    xpath=//input[@name='password']    password
    Input Text    xpath=//input[@name='confirm_password']    password

    Click Element    css=button[type='submit']
    

Get All Users
    ${name_list}    Create List
    ${rows}    Get WebElements    xpath=//table/tbody/tr
    ${len}    Get Length    ${rows}

    FOR    ${i}    IN RANGE    1    ${len}+1
        
        ${USER_DICT}    Create Dictionary

        ${name_locator}    Set Variable    ((//tbody//tr)[${i}]//td)[2]//a//div
        ${last_seen_locator}    Set Variable    ((//tbody//tr)[${i}]//td)[3]//span  
        ${orders_locator}    Set Variable    ((//tbody//tr)[${i}]//td)[4]//span  
        ${total_locator}    Set Variable    ((//tbody//tr)[${i}]//td)[5]//span  
        ${latest_locator}    Set Variable    ((//tbody//tr)[${i}]//td)[6]  
        ${news_locator}        Set Variable    ((//tbody//tr)[${i}]//td)[7]
        ${segment_locator}        Set Variable    ((//tbody//tr)[${i}]//td)[8]//div

        ${name}    Get Text    ${name_locator}
        ${status}    Run Keyword And Return Status    Page Should Contain    ${name_locator}//img
        IF    not ${status}
            ${name}    Evaluate    r"""${name}""".replace("\\n","")[1:]
        END

        ${last_seen}    Get Text    ${last_seen_locator}
        ${orders}    Get Text    ${orders_locator}
        ${total}    Get Text    ${total_locator}
        ${latest_status}    Run Keyword And Return Status    Page Should Contain    ${latest_locator}//span
        IF  ${latest_status}
            ${latest}    Get Text    ${latest_locator}//span
        ELSE
            ${latest}    Set Variable    ""
        END

        
        ${news}    Get Element Attribute    ${news_locator}//span//*[name()='svg']    aria-label
        


        ${segment_status}    Run Keyword And Return Status    Page Should Contain    ${segment_locator}//div//span
        IF  ${segment_status}
            ${segment}    Get Text    ${segment_locator}//div//span
        ELSE
            ${segment}    Set Variable    ""
        END

        

        Set To Dictionary    ${USER_DICT}    name    ${name}
        Set To Dictionary    ${USER_DICT}    status    ${status}
        Set To Dictionary    ${USER_DICT}    last_seen    ${last_seen}
        Set To Dictionary    ${USER_DICT}    orders    ${orders}
        Set To Dictionary    ${USER_DICT}    total    ${total}
        Set To Dictionary    ${USER_DICT}    latest    ${latest}
        Set To Dictionary    ${USER_DICT}    news    ${news}
        Set To Dictionary    ${USER_DICT}    segment    ${segment}
        
        Append To List    ${name_list}    ${USER_DICT}
    END
    Set Suite Variable    ${CUSTOMERS}    ${name_list}
    



Log New And Existing User
    ${new_users}    Evaluate    [user['name'] for user in $USERS]
    
    FOR    ${customer}    IN    @{CUSTOMERS}
        ${cus_name}    Set Variable    ${customer['name']}
        ${is_existing}    Evaluate    "${cus_name}" in ${new_users}

        IF  ${is_existing}
            Log To Console    Test Created User: ${customer['name']}
        ELSE
            Log To Console    Existing User: ${customer['name']}
        END
        Log Customer Details    ${customer}\n
    END

Log Customer Details
    [Arguments]    ${customer}
    Log To Console    Last Seen: ${customer['last_seen']}
    Log To Console    Orders: ${customer['orders']}
    Log To Console    Total Spent: ${customer['total']}
    Log To Console    Latest Purchase: ${customer['latest']}
    Log To Console    News: ${customer['news']}
    Log To Console    Segments: ${customer['segment']}

Open Identity Modal
    Click Element    xpath=//a[@aria-label='Create']

Input Date
    [Arguments]    ${locator}    ${date}
    Click Element At Coordinates    ${locator}    0    0
    Press Keys    ${None}    ${date}

Count Customer Orders
    ${users_with_zero_orders}    Create List

    FOR    ${customer}    IN    @{CUSTOMERS}
        ${orders}    Set Variable    ${customer['orders']}
        
        IF    ${orders} == 0
            Append To List    ${users_with_zero_orders}    ${customer['name']}
        END
    END

    Run Keyword If    ${users_with_zero_orders}    Fail    Users with 0 orders found: ${users_with_zero_orders}
