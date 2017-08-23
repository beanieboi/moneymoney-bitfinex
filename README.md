# Bitfinex-MoneyMoney

Fetches balances from Bitfinex API and returns them as securities

## Setup

* Download Bitfinex extension bitfinex.lua
* In MoneyMoney app open “Help” Menu and hit “Show database in finder” (https://moneymoney-app.com/extensions/#installation)
* Copy bitfinex.lua in extensions folder
* In MoneyMoney app open “Preferences” > “Extensions” and make sure “bitfinex” show up (to use unsigned extension uncheck “verify digital signatures of extensions” at the bottom)
* Login to bitfinex.com
* To get an API key, go to "Account" > "API" (https://www.bitfinex.com/api)
* Allow permission “READ Wallets” and hit “Generate key”
* Finally in MoneyMoney add new Bitfinex account and use your Bitfinex API key and API secret

### MoneyMoney

Add a new account (type Bitfinex Account”)

## Known Issues and Limitations

* Always assumes EUR as base currency
* Fetches current USD to Euro conversions from fixer.io
