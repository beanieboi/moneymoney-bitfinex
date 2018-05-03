-- Inofficial Bitfinex Extension (www.bitfinex.com) for MoneyMoneyApp
-- Fetches balances from Bitfinex API and returns them as securities
--
-- Username: Bitfinex API Key
-- Password: Bitfinex API Secret
--
-- Copyright (c) 2017 beanieboi
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

WebBanking{
  version = 1.0,
  url = "https://api.bitfinex.com",
  description = "Fetch balances from Bitfinex API and list them as securities",
  services= { "Bitfinex Account" },
}

local apiKey
local apiSecret
local apiVersion = "v2"
local currency = "EUR" -- fixme: Don't hardcode
local currencyName = "EUR" -- fixme: Don't hardcode
local market = "Bitfinex"
local accountName = "Balances"
local accountNumber = "Main"
local balances
local usdToEurRate
local prices

local currencySymbols = {
  AGI = "tAGIUSD",
  AID = "tAIDUSD",
  AIO = "tAIOUSD",
  ANT = "tANTUSD",
  AVT = "tAVTUSD",
  BAT = "tBATUSD",
  BCH = "tBCHUSD",
  BCI = "tBCIUSD",
  BFT = "tBFTUSD",
  BTC = "tBTCUSD",
  BTG = "tBTGUSD",
  CFI = "tCFIUSD",
  DAI = "tDAIUSD",
  DAT = "tDATUSD",
  DSH = "tDSHUSD",
  DTH = "tDTHUSD",
  EDO = "tEDOUSD",
  ELF = "tELFUSD",
  EOS = "tEOSUSD",
  ETC = "tETCUSD",
  ETH = "tETHUSD",
  ETP = "tETPUSD",
  FUN = "tFUNUSD",
  GNT = "tGNTUSD",
  IOS = "tIOSUSD",
  IOT = "tIOTUSD",
  LRC = "tLRCUSD",
  LTC = "tLTCUSD",
  MIT = "tMITUSD",
  MNA = "tMNAUSD",
  MTN = "tMTNUSD",
  NEO = "tNEOUSD",
  ODE = "tODEUSD",
  OMG = "tOMGUSD",
  QSH = "tQSHUSD",
  QTM = "tQTMUSD",
  RCN = "tRCNUSD",
  RDN = "tRDNUSD",
  REP = "tREPUSD",
  REQ = "tREQUSD",
  RLC = "tRLCUSD",
  RRT = "tRRTUSD",
  SAN = "tSANUSD",
  SNG = "tSNGUSD",
  SNT = "tSNTUSD",
  SPK = "tSPKUSD",
  STJ = "tSTJUSD",
  TNB = "tTNBUSD",
  TRX = "tTRXUSD",
  WAX = "tWAXUSD",
  XLM = "tXLMUSD",
  XMR = "tXMRUSD",
  XRP = "tXRPUSD",
  XVG = "tXVGUSD",
  YYW = "tYYWUSD",
  ZEC = "tZECUSD",
  ZRX = "tZRXUSD"
}

function SupportsBank(protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Bitfinex Account"
end

function InitializeSession(protocol, bankCode, username, username2, password, username3)
  apiKey = username
  apiSecret = password

  usdToEurRate = getUsdToEurRate()
  balances = queryPrivate("auth/r/wallets")

  prices = getRates()
end

function ListAccounts(knownAccounts)
  local account = {
    name = accountName,
    accountNumber = accountNumber,
    currency = currency,
    portfolio = true,
    type = "AccountTypePortfolio"
  }

  return {account}
end

function RefreshAccount(account, since)
  local name
  local currencyName
  local s = {}

  for index, values in pairs(balances) do
    currencyName = values[2]
    shares  = tonumber(values[3])

    if prices[currencyName] ~= nil and shares > 0 then
      s[#s+1] = {
        name = currencyName,
        market = market,
        currency = nil,
        quantity = shares,
        price = prices[currencyName] ~= nil and prices[currencyName] or 1
      }
    end
  end

  return {securities=s}
end

function EndSession ()
end

function queryPrivate(method, request)
  if request == nil then
    request = {}
  end

  local path = string.format("/%s/%s", apiVersion, method)
  local nonce = string.format("%d", math.floor(MM.time() * 1000000))
  local postData = httpBuildQuery(request)
  local message = string.format("/api%s%s%s", path, nonce, postData)
  local signature = bin2hex(MM.hmac384(apiSecret, message))

  local headers = {}

  headers['bfx-nonce'] = nonce
  headers["bfx-apikey"] = apiKey
  headers["bfx-signature"] = signature

  connection = Connection()
  content = connection:request("POST", url .. path, postData, "application/x-www-form-urlencoded; charset=UTF-8", headers)

  json = JSON(content)

  return json:dictionary()
end

function bin2hex(s)
 return (s:gsub(".", function (byte)
   return string.format("%02x", string.byte(byte))
 end))
end

function httpBuildQuery(params)
  local str = ''
  for key, value in pairs(params) do
    str = str .. key .. "=" .. value .. "&"
  end
  return str.sub(str, 1, -2)
end

function getRates()
  local rates = {USD = 1 * usdToEurRate}
  local path = string.format("/%s/tickers", apiVersion)
  local query = httpBuildQuery({symbols=currencySymbolsString()})

  connection = Connection()
  content = connection:request("GET", url .. path .. "?" .. query)
  json = JSON(content):dictionary()

  for index, values in pairs(json) do
    local symbol = values[1]
    local price = tonumber(values[8]) * usdToEurRate
    local currency = getKeyFromSymbol(symbol)

    rates[currency] = price
  end

  return rates
end

function getKeyFromSymbol(symbol)
  for key, value in pairs(currencySymbols) do
    if value == symbol then
      return key
    end
  end
end

function getUsdToEurRate()
  connection = Connection()
  content = connection:request("GET", "http://api.fixer.io/latest?base=USD&symbols=EUR")
  json = JSON(content):dictionary()

  return json["rates"]["EUR"]
end

function currencySymbolsString()
  local s = ""

  for key, name in pairs(currencySymbols) do
    s = s .. string.format("%s,", name)
  end

  return s
end
