-- Inofficial auxmoney Extension (https://www.auxmoney.com) for MoneyMoney
-- Fetches funds from auxmoney and returns them as securities
--
-- Copyright (c) 2018 Robert Gering
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

WebBanking {
  version = 1.0,
  country = "de",
  description = string.format(MM.localizeText("Fetch funds from %s and list them as securities"), "auxmoney"),
  services = { "auxmoney" },
}

-- State
local connection = Connection()
local html

-- Constants
local market = "auxmoney"
local currency = "EUR"

function SupportsBank(protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "auxmoney"
end

function InitializeSession(protocol, bankCode, username, username2, password, username3)
  MM.printStatus("Login")
  -- Fetch login page.
  connection.language = "de-de"
  html = HTML(connection:get("https://www.auxmoney.com/login"))

  html:xpath("//input[@name='login[loginUsername]']"):attr("value", username)
  html:xpath("//input[@name='login[loginPassword]']"):attr("value", password)

  html = HTML(connection:request(html:xpath("//input[@id='loginSubmit']"):click()))

  if html:xpath("//a[@href='/logout']"):length() == 0 then
  	MM.printStatus("Login Failed")
    return LoginFailed
  end
end

function ListAccounts(knownAccounts)
  -- Parse account info
  local name = "auxmoney Gebundenes Kapital"
  local owner = html:xpath("//div[@class='sessionInfo--user']//a"):text()
  local accountNumber = stripChars(html:xpath("//div[@class='sessionInfo--user']//em"):text(), "()")

  local account = {
    name = name,
    owner = owner,
    accountNumber = accountNumber,
    currency = currency,
    portfolio = true,
    type = AccountTypePortfolio
  }

  return {account}
end

function RefreshAccount(account, since)
  -- Follow redirect
  html = HTML(connection:get("https://www.auxmoney.com/anlegercockpit/portfolio"))

  -- Parse positions
  local runningProjectsName = "laufende Projekte"
  local runningProjectsValue = tonumber(stripChars(html:xpath("(//table[@id='payback-table']//td[@class='text-right value'])[6]"):text(), ".,€ "))
  local cancelledProjectsName = "ausgefallene Projekte"
  local cancelledProjectsValue = tonumber(stripChars(html:xpath("(//table[@id='payback-table']//td[@class='text-right value'])[7]"):text(), ".,€ "))
  local selledProjectsName = "verkaufte Projekte"
  local selledProjectsValue = tonumber(stripChars(html:xpath("(//table[@id='payback-table']//td[@class='text-right value'])[8]"):text(), ".,€ "))

  local s = {}
  s[#s+1] = {
    name = runningProjectsName,
    market = market,
    currency = currency,
    amount = runningProjectsValue,
  }

  s[#s+1] = {
    name = cancelledProjectsName,
    market = market,
    currency = currency,
    amount = cancelledProjectsValue,
  }

  s[#s+1] = {
    name = selledProjectsName,
    market = market,
    currency = currency,
    amount = selledProjectsValue,
  }

  return {securities = s}
end

function EndSession()
  html = HTML(connection:request(html:xpath("//a[@href='/logout']"):click()))  
end

-- Helper

function stripChars(str, chrs)
  local s = str:gsub("["..chrs:gsub("%W","%%%1").."]", '')
  return s
end

