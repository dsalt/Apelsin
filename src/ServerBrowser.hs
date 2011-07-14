module ServerBrowser where
import Graphics.UI.Gtk
import Control.Concurrent.STM
import Data.IORef
import qualified Data.ByteString.Char8 as B
import Data.Ord
import Network.Tremulous.Protocol
import Text.Printf

import Types
import GtkUtils
import FilterBar
import InfoBox
import TremFormatting
import Constants
import Config

newServerBrowser :: Bundle -> SetCurrent -> IO (VBox, PolledHook)
newServerBrowser Bundle{browserStore=raw, ..} setServer = do
	Config {..}	<- atomically $ readTMVar mconfig
	filtered	<- treeModelFilterNew raw []
	sorted		<- treeModelSortNewWithModel filtered	
	view		<- treeViewNewWithModel sorted
	
	addColumnsFilterSort raw filtered sorted view (Just (comparing gameping)) [
		  ("_Game"	, 0	, False	, False	, False	, showGame , Just (comparing (\x -> (protocol x, gamemod x))))
		, ("_Name"	, 0	, True	, True	, True	, pangoPretty colors . hostname	, Just (comparing hostname))
		, ("_Map"	, 0	, True	, False	, False	, take 16 . unpackorig . mapname	, Just (comparing mapname))
		, ("P_ing"	, 1	, False	, False , False	, show . gameping	, Just (comparing gameping))
		, ("_Players"	, 1	, False	, False , False	, showPlayers		, Just (comparing nplayers))
		]

	(infobox, statNow, statTot, statRequested) <- newInfoboxBrowser
	
	(filterbar, current) <- newFilterBar filtered statNow filterBrowser
	empty <- checkButtonNewWithMnemonic "_empty"
	set empty [ toggleButtonActive := filterEmpty ]
	boxPackStart filterbar empty PackNatural 0
	on empty toggled $ do
		treeModelFilterRefilter filtered
		n <- treeModelIterNChildren filtered Nothing
		set statNow [ labelText := show n ]


	treeModelFilterSetVisibleFunc filtered $ \iter -> do
		GameServer{..}	<- treeModelGetRow raw iter
		s		<- readIORef current
		showEmpty	<- toggleButtonGetActive empty
		return $ (showEmpty || not (null players)) && (B.null s ||
			smartFilter s [
				  cleanedCase hostname
				, cleanedCase mapname
				, proto2string protocol
				, maybe "" cleanedCase gamemod
				])
			
	on view cursorChanged $ do
		(path, _) <- treeViewGetCursor view
		setServer False =<< getElementFS raw sorted filtered path

	on view rowActivated $ \path _ ->
		setServer True =<< getElementFS raw sorted filtered path
		
	scrollview <- scrolledWindowNew Nothing Nothing
	scrolledWindowSetPolicy scrollview PolicyNever PolicyAlways
	containerAdd scrollview view
	
	let updateF PollResult{..} = do
		listStoreClear raw
		treeViewColumnsAutosize view
		mapM_ (listStoreAppend raw) polled
		treeModelFilterRefilter filtered
		set statTot		[ labelText := show serversResponded ]
		set statRequested	[ labelText := show (serversRequested-serversResponded) ]
		n <- treeModelIterNChildren filtered Nothing
		set statNow 		[ labelText := show n ]
		
	box <- vBoxNew False 0
	boxPackStart box filterbar PackNatural spacing
	boxPackStart box scrollview PackGrow 0
	boxPackStart box infobox PackNatural 0
	
	return (box, updateF)
	where
	showGame GameServer{..} = proto2string protocol ++ maybe "" (("-"++) . htmlEscape . unpackorig) gamemod
	showPlayers GameServer{..} = printf "%d / %2d" nplayers slots
