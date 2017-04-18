module Flags exposing (Flags, blankFlags)


{-| The flags passed to the program from javascript upon init.
-}
type alias Flags =
    { apiBaseUrl : String }


{-| We don't need default flags because they're all passed from javascript upon init, so we can just use blank ones.
-}
blankFlags : Flags
blankFlags =
    { apiBaseUrl = "" }
