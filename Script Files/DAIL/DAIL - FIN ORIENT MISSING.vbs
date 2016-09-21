'Required for statistical purposes===============================================================================
name_of_script = "DAIL - FIN ORIENT MISSING.vbs"
start_time = timer
STATS_counter = 1              'sets the stats counter at one
STATS_manualtime = 64          'manual run time in seconds
STATS_denomination = "C"       'C is for Case
'END OF stats block==============================================================================================

'LOADING FUNCTIONS LIBRARY FROM GITHUB REPOSITORY===========================================================================
IF IsEmpty(FuncLib_URL) = TRUE THEN	'Shouldn't load FuncLib if it already loaded once
	IF run_locally = FALSE or run_locally = "" THEN	   'If the scripts are set to run locally, it skips this and uses an FSO below.
		IF use_master_branch = TRUE THEN			   'If the default_directory is C:\DHS-MAXIS-Scripts\Script Files, you're probably a scriptwriter and should use the master branch.
			FuncLib_URL = "https://raw.githubusercontent.com/MN-Script-Team/BZS-FuncLib/master/MASTER%20FUNCTIONS%20LIBRARY.vbs"
		Else											'Everyone else should use the release branch.
			FuncLib_URL = "https://raw.githubusercontent.com/MN-Script-Team/BZS-FuncLib/RELEASE/MASTER%20FUNCTIONS%20LIBRARY.vbs"
		End if
		SET req = CreateObject("Msxml2.XMLHttp.6.0")				'Creates an object to get a FuncLib_URL
		req.open "GET", FuncLib_URL, FALSE							'Attempts to open the FuncLib_URL
		req.send													'Sends request
		IF req.Status = 200 THEN									'200 means great success
			Set fso = CreateObject("Scripting.FileSystemObject")	'Creates an FSO
			Execute req.responseText								'Executes the script code
		ELSE														'Error message
			critical_error_msgbox = MsgBox ("Something has gone wrong. The Functions Library code stored on GitHub was not able to be reached." & vbNewLine & vbNewLine &_
                                            "FuncLib URL: " & FuncLib_URL & vbNewLine & vbNewLine &_
                                            "The script has stopped. Please check your Internet connection. Consult a scripts administrator with any questions.", _
                                            vbOKonly + vbCritical, "BlueZone Scripts Critical Error")
            StopScript
		END IF
	ELSE
		FuncLib_URL = "C:\BZS-FuncLib\MASTER FUNCTIONS LIBRARY.vbs"
		Set run_another_script_fso = CreateObject("Scripting.FileSystemObject")
		Set fso_command = run_another_script_fso.OpenTextFile(FuncLib_URL)
		text_from_the_other_script = fso_command.ReadAll
		fso_command.Close
		Execute text_from_the_other_script
	END IF
END IF
'END FUNCTIONS LIBRARY BLOCK================================================================================================


'------------------THIS SCRIPT IS DESIGNED TO BE RUN FROM THE DAIL SCRUBBER.
'------------------As such, it does NOT include protections to be ran independently.
BeginDialog FIN_ori_dialog, 0, 0, 301, 100, "Financial Orientation dialog"
  EditBox 65, 5, 120, 15, client_name
  EditBox 265, 5, 25, 15, ref_num
  EditBox 100, 25, 85, 15, Edit6
  CheckBox 5, 45, 205, 10, "Check here to have the script fill this referral date on EMPS", update_emps_checkbox
  EditBox 50, 60, 240, 15, other_notes
  EditBox 70, 80, 100, 15, worker_signature
  ButtonGroup ButtonPressed
    OkButton 185, 80, 50, 15
    CancelButton 240, 80, 50, 15
  Text 5, 10, 60, 10, "Name from DAIL:"
  Text 195, 10, 70, 10, "HH member number:"
  Text 5, 30, 90, 10, "Financial Orientation Date:"
  Text 5, 65, 40, 10, "Other notes:"
  Text 5, 85, 60, 10, "Worker signature:"
EndDialog



EMConnect ""
EMReadScreen MAXIS_case_number, 8, 5, 73
MAXIS_case_number = trim(MAXIS_case_number)

EMReadScreen name_for_dail, 57, 5, 5
other_person = InStr(name_for_dail, "--(")
'MsgBox other_person
If other_person = 0 Then 
	comma_loc = InStr(name_for_dail, ",")
	dash_loc = InStr(name_for_dail, "-")
	EMReadscreen last_name, comma_loc - 1, 5, 5
	EMReadscreen middle_exists, 1, 5, 5 + (dash_loc - 2)
	If middle_exists = " " Then 
		EMReadscreen first_name, dash_loc - comma_loc - 5, 5, comma_loc + 5
	Else 
		EMReadScreen first_name, dash_loc - comma_loc - 3, 5, comma_loc + 5
	End If 
Else 
	end_other = InStr(name_for_dail, ")--")
	comma_loc = InStr(other_person, name_for_dail, ",")
	EMReadscreen last_name, comma_loc - other_person - 3, 5, other_person + 7
	EMReadscreen middle_exists, 1, 5, 5 + end_other
	If middle_exists = " " Then 
		EMReadscreen first_name, end_other - comma_loc - 3, 5, comma_loc + 5
	Else 
		EMReadScreen first_name, end_other - comma_loc - 1, 5, comma_loc + 5
	End If 
End If 
client_name = last_name & ", " & first_name

msgbox client_name

EMSendKey "i"
transmit

EMSendKey "work"
transmit

EMReadScreen work_panel_check, 4, 2, 51
If work_panel_check = "WORK" Then 
work_maxis_row = 7
	DO
		EMReadScreen work_name, 26, work_maxis_row, 7			'Reads the client name from INFC/WORK'
		work_name = trim(work_name)
		IF client_name = work_name then 
			memb_check = vbYes		'If the name on INFC/WORK exactly matches the name from the initial excel list, the script does not need user input and will gather the PMI and Reference Number'
			EMReadScreen ref_numb, 2, work_maxis_row, 3
		ElseIf client_name <> work_name then 	'if name doesn't match the referral name the confirmation is required by the user
			memb_check = MsgBox ("DAIL Message is for - " & client_name & vbNewLine & "Name on INFC/WORK - " & work_name & _ 
			  vbNewLine & vbNewLine & "Is this the client you need ES Referral Information about?", vbYesNo + vbQuestion, "Confirm Client using Banked Monhts")
			If memb_check = vbYes Then		'If the user confirms that this is the correct client, the PMI and Ref number are gathered'
				EMReadScreen ref_numb, 2, work_maxis_row, 3
			ElseIf memb_check = vbNo Then	'If the user says NO the script will see if there are other clients listed on INFC/WORK and start back at the beginning of the loop to try to match'
				EMReadScreen next_clt, 1, (work_maxis_row + 1), 7
			END IF
		End If 
		work_maxis_row = work_maxis_row + 1		'Increments to read the next row for a new client'
	Loop until next_clt = " " OR memb_check = vbYes	
	
	If memb_check = vbYes Then EMReadScreen es_appt_date, 8, 7, 72
	If es_appt_date = "__ __ __" Then es_appt_date = ""
	es_appt_date = replace(es_ref_date, " ", "/")
End If 

If es_appt_date <> "" Then 
	appt_date_msg = MsgBox ("It appears that this client " & client_name & " had an appointment with ES on " & es_appt_date & vbNewLine & vbNewLine & "Would you like to use this date as the Financial Orientation date?", vbYesNo + vbQuestion, "Use Appointment Date?")
	If appt_date_msg = vbYes then fin_orient_date = es_appt_date
End If 

If fin_orient_date = "" Then 
	PF3
	EMSendKey "s"
	transmit
	
	EMSendKey "prog"
	transmit

	EMReadScreen cash_actv_check, 4, 6, 47
	If cash_actv_check = "ACTV" Then
		EMReadScreen cash_intv_date, 8, 6, 55
		If cash_intv_date = "__ __ __" Then cash_intv_date = ""
		cash_intv_date = replace(cash_intv_date, " ", "/")
	Else 
		EMReadScreen cash_actv_check, 4, 7, 47
		If cash_actv_check = "ACTV" Then
			EMReadScreen cash_intv_date, 8, 6, 55
			If cash_intv_date = "__ __ __" Then cash_intv_date = ""
			cash_intv_date = replace(cash_intv_date, " ", "/")
		End If 
	End If 
	
	If cash_intv_date <> "" Then 
		intv_date_msg = MsgBox ("It appears that this case was interviewed for cash on " & cash_intv_date & vbNewLine & vbNewLine & "Would you like to use this date as the Financial Orientation date?", vbYesNo + vbQuestion, "Use Interview Date?")
		If intv_date_msg = vbYes then fin_orient_date = cash_intv_date
	End If 
	PF3
End If 

If fin_orient_date = "" Then 
	PF3
	EMSendKey "s"
	transmit
	
	EMSendKey "emps"
	transmit

	EMReadScreen es_ref_date, 8, 16, 40
	If es_ref_date = "__ __ __" Then es_ref_date = ""
	es_ref_date = replace(es_ref_date, " ", "/")
	
	If es_ref_date <> "" Then 
		intv_date_msg = MsgBox ("It appears that this case was interviewed for cash on " & es_ref_date & vbNewLine & vbNewLine & "Would you like to use this date as the Financial Orientation date?", vbYesNo + vbQuestion, "Use Interview Date?")
		If intv_date_msg = vbYes then fin_orient_date = cash_intv_date
	End If 
	PF3
End If 

update_emps_checkbox = checked 

Do 
	err_msg = ""
	Dialog FIN_ori_dialog
	cancel_confirmation
	If worker_signature = "" Then err_msg = err_msg & vbNewLine & "Sign your case note."
	If isdate(fin_orient_date) = FALSE Then err_msg = err_msg & vbNewLine & "You must enter a valid date for the ES Referral Date."
	If update_emps_checkbox = checked AND fin_orient_date = "" Then err_msg = err_msg & vbNewLine & "You must have a date entered for the script to update EMPS"
	If update_emps_checkbox = checked AND ref_numb = "" Then err_msg = err_msg & vbNewLine & "You must enter the client's reference number in order for the EMPS panel to be correctly updated."
	If err_msg <> "" Then MsgBox "Please resolve before you continue." & vbNewLine & err_msg
Loop until err_msg = ""

'Check to make sure we are back to our dail 
EMReadScreen DAIL_check, 4, 2, 48 
IF DAIL_check <> "DAIL" THEN 
	PF3 'This should bring us back from UNEA or other screens 
	EMReadScreen DAIL_check, 4, 2, 48 
	IF DAIL_check <> "DAIL" THEN 'If we are still not at the dail, try to get there using custom function, this should result in being on the correct dail (but not 100%) 
		call navigate_to_MAXIS_screen("DAIL", "DAIL") 
	END IF 
END IF 
EMWriteScreen "n", 6, 3 
transmit 

If update_emps_checkbox = checked Then 
	PF9 
	EMReadScreen case_note_mode_check, 7, 20, 3 
	If case_note_mode_check <> "Mode: A" then MsgBox "You are not in a case note on edit mode. You might be in inquiry. Try the script again in production." 
	If case_note_mode_check <> "Mode: A" then stopscript

	Call Write_Variable_in_CASE_NOTE ("DAIL Processed - Financial Orientation Date Updated for Memb " & ref_numb)
	Call Write_Variable_in_CASE_NOTE ("* PEPR message rec'vd indicating that EMPS panel was missing ES Referral Date")
''	If memb_check = vbYes Then Call Write_Variable_in_CASE_NOTE ("* ES Referral Date found on INFC/WORK and added to EMPS")
	Call Write_Bullet_and_Variable_in_Case_Note ("Date Entered", fin_orient_date)
	Call Write_Bullet_and_Variable_in_Case_Note ("Notes", other_notes)
	Call Write_Variable_in_CASE_NOTE ("---")
	Call Write_Variable_in_CASE_NOTE (worker_signature) 
	end_msg = "Success! EMPS has been updated and Case Note Written"
Else 
	end_msg = "You have selected to not have the EMPS panel updated by the script." & vbNewLine & "You will need to process this DAIL manually."

End If 

script_end_procedure(end_msg)