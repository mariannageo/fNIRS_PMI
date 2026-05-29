function buttonPress(mainwin, key1, key2)
% simple button Press to continue the experiment
% mainwin:  window varibla from Psychtoolbox
% key1:     button for continue (e.g., enter)
% key2:     button for interruption ( e.g., escape)

% keyboard response
 keyIsDown = 0;
 while 1
     [keyIsDown, secs, keyCode] = KbCheck;
     FlushEvents('keyDown');
     if keyIsDown
         nKeys = sum(keyCode);
         if nKeys == 1
             if keyCode(key1)
                 Screen('Flip', mainwin);
                 break;
             elseif keyCode(key2)
                 ShowCursor; %fclose(outfile);  
                 Screen('CloseAll'); return
             end
             keyIsDown = 0; keyCode = 0;
         end
     end
 end