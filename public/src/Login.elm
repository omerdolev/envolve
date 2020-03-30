module Login exposing (Model, Msg, init, subscriptions, update, view)

import Html exposing (Html, button, div, form, input, label, text)
import Html.Attributes exposing (disabled, for, id, type_, value)
import Html.Events exposing (onInput, preventDefaultOn)
import Json.Decode as Json
import Socket exposing (openConnection)
import Socket.ConnectionString as Conn
import Url exposing (Url)
import Url.Parser exposing (parse, string)


type Msg
    = UserNameEntered String
    | FormSubmit
    | LoginSuccessful


type alias Model =
    { url : Url
    , roomId : Maybe String
    , userName : String
    , formState : FormState
    }


type FormState
    = InputtingUserName
    | PendingConnection


init : Url -> ( Model, Cmd Msg )
init url =
    ( { url = url, roomId = parse string url, userName = "", formState = InputtingUserName }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg, Bool )
update msg model =
    case ( msg, model.formState ) of
        ( UserNameEntered newUserName, InputtingUserName ) ->
            ( { model | userName = newUserName }, Cmd.none, False )

        ( FormSubmit, InputtingUserName ) ->
            let
                connectionString =
                    Conn.fromUrl model.url model.userName model.roomId
            in
            ( { model | formState = PendingConnection }, openConnection connectionString, False )

        ( LoginSuccessful, PendingConnection ) ->
            ( model, Cmd.none, True )

        ( _, _ ) ->
            ( model, Cmd.none, False )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Socket.connected (always LoginSuccessful)


view : Model -> Html Msg
view model =
    case model.formState of
        InputtingUserName ->
            viewInput model.userName

        PendingConnection ->
            viewPending model.userName


viewInput : String -> Html Msg
viewInput currentUserName =
    form [ onSubmit FormSubmit ]
        [ label [ for "name-input" ] [ text "Please enter your name: " ]
        , input [ onInput UserNameEntered, id "name-input", value currentUserName ] []
        , button [ type_ "submit" ] [ text "Enter" ]
        ]


viewPending : String -> Html Msg
viewPending currentUserName =
    div []
        [ label [ for "name-input" ] [ text "Please enter your name: " ]
        , input [ id "name-input", value currentUserName, disabled True ] []
        , button [ disabled True ] [ text "Enter" ]
        ]


onSubmit : Msg -> Html.Attribute Msg
onSubmit msg =
    preventDefaultOn "submit" (Json.succeed ( msg, True ))
