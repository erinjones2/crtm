;+
PRO OSRF::Compute_Central_Frequency, $
  Debug=Debug
;-
  ; Set up
  COMPILE_OPT HIDDEN
  ; ...OSRF parameters
  @osrf_parameters
  ; ...Set up error handler
  @osrf_pro_err_handler


  ; Check if object has been allocated
  IF ( ~self.Associated(Debug=Debug) ) THEN $
    MESSAGE, 'OSRF object has not been allocated.', $
             NONAME=MsgSwitch, NOPRINT=MsgSwitch


  ; Compute the SRF first moment.
  f0 = self.Convolve(self.frequency, Debug=Debug)
  
  
  ; Set the central frequency value
  self.f0 = f0
  self.Set_Flag, /f0_Computed, Debug=Debug

END
