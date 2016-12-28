module Config exposing (baseUrl, apiBaseUrl)


apiBaseUrl : String
apiBaseUrl =
    baseUrl ++ "api/"


{-| The app base url.

On the backend we don't ever need to specify the full URL, but I believe on the
front-end you have to, this needs to be checked...

#CHANGE4PROD.
-}
baseUrl : String
baseUrl =
    "http://localhost:3000/"
