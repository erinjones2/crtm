!
! RadDiag_Stats_Define
!
! Module defining the RadDiag_Stats structure
! and containing routines to manipulate it.
!
!
! CREATION HISTORY:
!       Written by:     Paul van Delst, 28-Mar-2006
!                       paul.vandelst@noaa.gov
!

MODULE RadDiag_Stats_Define

  ! -----------------
  ! Environment setup
  ! -----------------
  ! Module use
  USE Type_Kinds,      ONLY: sp=>Single
  USE Message_Handler, ONLY: FAILURE, SUCCESS, INFORMATION, Display_Message
  ! Disable implicit typing
  IMPLICIT NONE


  ! ---------------------
  ! Explicit visibilities
  ! ---------------------
  ! Everything private by default
  PRIVATE
  ! Parameters
  PUBLIC :: iBC   
  PUBLIC :: iNBC  
  PUBLIC :: iScan 
  PUBLIC :: iConst
  PUBLIC :: iAngle
  PUBLIC :: iLpsR 
  PUBLIC :: iLpsR2
  PUBLIC :: iCLW
  ! Datatypes
  PUBLIC :: RadDiag_Stats_type
  ! Procedures
  PUBLIC :: RadDiag_Stats_Associated
  PUBLIC :: RadDiag_Stats_Destroy
  PUBLIC :: RadDiag_Stats_Create
  PUBLIC :: RadDiag_Stats_Inspect
  PUBLIC :: RadDiag_Stats_DefineVersion


  ! -----------------
  ! Module parameters
  ! -----------------
  INTEGER, PARAMETER :: N_VARIABLES = 8
  INTEGER, PARAMETER :: iBC    = 1
  INTEGER, PARAMETER :: iNBC   = 2
  INTEGER, PARAMETER :: iScan  = 3
  INTEGER, PARAMETER :: iConst = 4
  INTEGER, PARAMETER :: iAngle = 5
  INTEGER, PARAMETER :: iLpsR  = 6
  INTEGER, PARAMETER :: iLpsR2 = 7
  INTEGER, PARAMETER :: iCLW   = 8
  CHARACTER(*), PARAMETER :: VARIABLENAMES(N_VARIABLES) = &
    (/ 'Obs-Calc dTb [Bias Corrected]          ', &
       'Obs-Calc dTb [NOT Bias Corrected]      ', &
       'SatBias Angle term                     ', &
       'SatBias AirMass Constant term          ', &
       'SatBias AirMass Angle term             ', &
       'SatBias AirMass Lapse Rate term        ', &
       'SatBias AirMass (Lapse Late)^2 term    ', &
       'SatBias AirMass Cloud Liquid Water term' /)
  ! Literal constants
  REAL, PARAMETER :: ZERO = 0.0_sp
  ! Version Id for the module
  CHARACTER(*), PARAMETER :: MODULE_VERSION_ID = &
  '$Id$'


  ! --------------------
  ! Structure definition
  ! --------------------
  !:tdoc+:
  TYPE :: RadDiag_Stats_type
    ! Dimensions
    INTEGER :: n_Predictors = 0  ! I
    INTEGER :: n_Channels   = 0  ! L
    INTEGER :: n_FOVs       = 0  ! Is
    INTEGER :: n_Times      = 0  ! It
    INTEGER :: n_Variables  = 0  ! N
    ! The variable names
    CHARACTER(80), ALLOCATABLE :: VariableNames(:)  ! N
    ! The channel numbers
    INTEGER,  ALLOCATABLE :: Channel(:)  ! L
    ! The Air Mass bias correction coefficients
    REAL(sp), ALLOCATABLE :: AirMassCoefficients(:,:,:)  ! I x L x It
    ! Scan position statistics
    INTEGER,  ALLOCATABLE :: FOV(:)              ! Is
    REAL(sp), ALLOCATABLE :: scan_Data(:,:,:)    ! N x L x Is
    INTEGER,  ALLOCATABLE :: scan_nSamples(:,:)  ! L x Is
    ! Time series statistics
    INTEGER,  ALLOCATABLE :: DateTime(:)         ! It
    REAL(sp), ALLOCATABLE :: time_Data(:,:,:)    ! N x L x It
    INTEGER,  ALLOCATABLE :: time_nSamples(:,:)  ! L x It
  END TYPE RadDiag_Stats_type
  !:tdoc-:


CONTAINS


!--------------------------------------------------------------------------------
!:sdoc+:
! NAME:
!       RadDiag_Stats_Associated
!
! PURPOSE:
!       Elemental function to test the status of the allocatable components
!       of a RadDiag_Stats object.
!
! CALLING SEQUENCE:
!       Status = RadDiag_Stats_Associated( RadDiag_Stats )
!
! OBJECTS:
!       RadDiag_Stats:   RadDiag_Stats structure which is to have its
!                        member's status tested.
!                        UNITS:      N/A
!                        TYPE:       RadDiag_Stats_type
!                        DIMENSION:  Scalar or any rank
!                        ATTRIBUTES: INTENT(IN)
!
! FUNCTION RESULT:
!       Status:  The return value is a logical value indicating the
!                status of the RadDiag_Stats members.
!                .TRUE.  - if ANY of the RadDiag_Stats allocatable or
!                          pointer members are in use.
!                .FALSE. - if ALL of the RadDiag_Stats allocatable or
!                          pointer members are not in use.
!                UNITS:      N/A
!                TYPE:       LOGICAL
!                DIMENSION:  Same as input RadDiag_Stats argument
!
!:sdoc-:
!--------------------------------------------------------------------------------

  FUNCTION RadDiag_Stats_Associated( RadDiag_Stats ) RESULT( Status )
    ! Arguments
    TYPE(RadDiag_Stats_type), INTENT(IN) :: RadDiag_Stats
    ! Function result
    LOGICAL :: Status

    ! Test the structure members
    Status = &
      ALLOCATED( RadDiag_Stats%VariableNames       ) .OR. &
      ALLOCATED( RadDiag_Stats%Channel             ) .OR. &
      ALLOCATED( RadDiag_Stats%AirMassCoefficients ) .OR. &
      ALLOCATED( RadDiag_Stats%FOV                 ) .OR. &
      ALLOCATED( RadDiag_Stats%scan_Data           ) .OR. &
      ALLOCATED( RadDiag_Stats%scan_nSamples       ) .OR. &
      ALLOCATED( RadDiag_Stats%DateTime            ) .OR. &
      ALLOCATED( RadDiag_Stats%time_Data           ) .OR. &
      ALLOCATED( RadDiag_Stats%time_nSamples       )

  END FUNCTION RadDiag_Stats_Associated


!--------------------------------------------------------------------------------
!:sdoc+:
!
! NAME:
!       RadDiag_Stats_Destroy
! 
! PURPOSE:
!       Elemental subroutine to re-initialize RadDiag_Stats objects.
!
! CALLING SEQUENCE:
!       CALL RadDiag_Stats_Destroy( RadDiag_Stats )
!
! OBJECTS:
!       RadDiag_Stats:  Re-initialized RadDiag_Stats structure.
!                       UNITS:      N/A
!                       TYPE:       RadDiag_Stats_type
!                       DIMENSION:  Scalar OR any rank
!                       ATTRIBUTES: INTENT(OUT)
!
!:sdoc-:
!--------------------------------------------------------------------------------

  ELEMENTAL SUBROUTINE RadDiag_Stats_Destroy( RadDiag_Stats )
    TYPE(RadDiag_Stats_type), INTENT(OUT) :: RadDiag_Stats
  END SUBROUTINE RadDiag_Stats_Destroy
  


!--------------------------------------------------------------------------------
!:sdoc+:
!
! NAME:
!       RadDiag_Stats_Create
! 
! PURPOSE:
!       Elemental subroutine to create an instance of the RadDiag_Stats object.
!
! CALLING SEQUENCE:
!       CALL RadDiag_Stats_Create( RadDiag_Stats, &
!                                  n_Predictors , &
!                                  n_Channels   , &
!                                  n_FOVs       , &
!                                  n_Times        )
!
! OBJECTS:
!       RadDiag_Stats:   RadDiag_Stats structure.
!                        UNITS:      N/A
!                        TYPE:       RadDiag_Stats_type
!                        DIMENSION:  Scalar or any rank
!                        ATTRIBUTES: INTENT(OUT)
!
! INPUTS:
!       n_Predictors:    Predictor dimension of RadDiag_Stats structure.
!                        Must be > 0.
!                        UNITS:      N/A
!                        TYPE:       INTEGER
!                        DIMENSION:  Conformable with RadDiag_Stats object
!                        ATTRIBUTES: INTENT(IN)
!
!       n_Channels:      Channel dimension of RadDiag_Stats structure.
!                        Must be > 0.
!                        UNITS:      N/A
!                        TYPE:       INTEGER
!                        DIMENSION:  Conformable with RadDiag_Stats object
!                        ATTRIBUTES: INTENT(IN)
!
!       n_FOVs:          Field-of-view dimension of RadDiag_Stats structure.
!                        Must be > 0.
!                        UNITS:      N/A
!                        TYPE:       INTEGER
!                        DIMENSION:  Conformable with RadDiag_Stats object
!                        ATTRIBUTES: INTENT(IN)
!
!       n_Times:         Time dimension of RadDiag_Stats structure.
!                        Must be > 0.
!                        UNITS:      N/A
!                        TYPE:       INTEGER
!                        DIMENSION:  Conformable with RadDiag_Stats object
!                        ATTRIBUTES: INTENT(IN)
!
!:sdoc-:
!--------------------------------------------------------------------------------

  ELEMENTAL SUBROUTINE RadDiag_Stats_Create( &
    RadDiag_Stats, &  ! Output
    n_Predictors , &  ! Input
    n_Channels   , &  ! Input
    n_FOVs       , &  ! Input
    n_Times        )  ! Input
    ! Arguments
    TYPE(RadDiag_Stats_type), INTENT(OUT) :: RadDiag_Stats
    INTEGER,                  INTENT(IN)  :: n_Predictors
    INTEGER,                  INTENT(IN)  :: n_Channels
    INTEGER,                  INTENT(IN)  :: n_FOVs
    INTEGER,                  INTENT(IN)  :: n_Times
    ! Local variables
    INTEGER :: alloc_stat

    ! Check input
    IF ( n_Predictors < 1 .OR. &
         n_Channels   < 1 .OR. &
         n_FOVs       < 1 .OR. &
         n_Times      < 1      ) RETURN

    ! Perform the allocation
    ALLOCATE( &
      RadDiag_Stats%VariableNames(N_VARIABLES), &
      RadDiag_Stats%Channel(n_Channels), &
      RadDiag_Stats%AirMassCoefficients(n_Predictors,n_Channels,n_Times), &
      RadDiag_Stats%FOV(n_FOVs), &
      RadDiag_Stats%scan_Data(N_VARIABLES,n_Channels,n_FOVs), &
      RadDiag_Stats%scan_nSamples(n_Channels,n_FOVs), &
      RadDiag_Stats%DateTime(n_Times), &
      RadDiag_Stats%time_Data(N_VARIABLES,n_Channels,n_Times), &
      RadDiag_Stats%time_nSamples(n_Channels,n_Times), &
      STAT = alloc_stat )
    IF ( alloc_stat /= 0 ) RETURN

    ! Initialise
    ! ...Dimensions
    RadDiag_Stats%n_Predictors = n_Predictors
    RadDiag_Stats%n_Channels   = n_Channels
    RadDiag_Stats%n_FOVs       = n_FOVs
    RadDiag_Stats%n_Times      = n_Times
    RadDiag_Stats%n_Variables  = N_VARIABLES
    ! ...Arrays
    RadDiag_Stats%VariableNames       = VARIABLENAMES
    RadDiag_Stats%AirMassCoefficients = ZERO
    RadDiag_Stats%Channel             = 0
    RadDiag_Stats%FOV                 = 0
    RadDiag_Stats%scan_Data           = ZERO
    RadDiag_Stats%scan_nSamples       = ZERO
    RadDiag_Stats%DateTime            = ZERO
    RadDiag_Stats%time_Data           = ZERO
    RadDiag_Stats%time_nSamples       = ZERO

  END SUBROUTINE RadDiag_Stats_Create


!--------------------------------------------------------------------------------
!:sdoc+:
!
! NAME:
!       RadDiag_Stats_Inspect
!
! PURPOSE:
!       Subroutine to print the contents of a RadDiag_Stats object to stdout.
!
! CALLING SEQUENCE:
!       CALL RadDiag_Stats_Inspect( rds )
!
! INPUTS:
!       rds:    RadDiag_Stats object to display.
!               UNITS:      N/A
!               TYPE:       RadDiag_Stats_type
!               DIMENSION:  Scalar
!               ATTRIBUTES: INTENT(IN)
!
!:sdoc-:
!--------------------------------------------------------------------------------

  SUBROUTINE RadDiag_Stats_Inspect( rds )
    TYPE(RadDiag_Stats_type), INTENT(IN) :: rds
    INTEGER :: i, j, k

    WRITE(*, '(1x,"RADDIAG_STATS OBJECT")')
    ! Dimensions
    WRITE(*, '(3x,"n_Predictors:",1x,i0)') rds%n_Predictors
    WRITE(*, '(3x,"n_Channels  :",1x,i0)') rds%n_Channels  
    WRITE(*, '(3x,"n_FOVs      :",1x,i0)') rds%n_FOVs      
    WRITE(*, '(3x,"n_Times     :",1x,i0)') rds%n_Times     
    WRITE(*, '(3x,"n_Variables :",1x,i0)') rds%n_Variables 
    IF ( .NOT. RadDiag_Stats_Associated(rds) ) RETURN
    ! Variable names
    WRITE(*, '(3x,"VariableNames :")')
    DO i = 1, rds%n_Variables
      WRITE(*, '(7x,i2,") ",a)') i, rds%VariableNames(i)
    END DO
    ! Channel number information
    WRITE(*, '(3x,"Channel:")') 
    WRITE(*, '(10(1x,i5,:))') rds%Channel
    ! Air mass bias correction coefficients
    WRITE(*, '(3x,"AirMassCoefficients:")')
    DO j = 1, rds%n_Times
      WRITE(*, '(5x,"Date/Time: ",i0)') rds%DateTime(j) 
      DO i = 1, rds%n_Channels
        WRITE(*, '(7x,"Channel: ",i0)') rds%Channel(i) 
        WRITE(*, '(5(1x,es13.6,:))') rds%AirMassCoefficients(:,i,j)
      END DO
    END DO
    ! Scan position statistics
    WRITE(*, '(3x,"Scan position statistics:")')
    DO j = 1, rds%n_FOVs
      WRITE(*, '(5x,"FOV: ",i0)') rds%FOV(j) 
      DO i = 1, rds%n_Channels
        WRITE(*, '(7x,"Channel: ",i0,"; n_Samples: ",i0)') rds%Channel(i), rds%scan_nSamples(i,j)
        WRITE(*, '(5(1x,es13.6,:))') rds%scan_Data(:,i,j)
      END DO
    END DO
    ! Time series statistics
    WRITE(*, '(3x,"Time series statistics:")')
    DO j = 1, rds%n_Times
      WRITE(*, '(5x,"Date/Time: ",i0)') rds%DateTime(j) 
      DO i = 1, rds%n_Channels
        WRITE(*, '(7x,"Channel: ",i0,"; n_Samples: ",i0)') rds%Channel(i), rds%time_nSamples(i,j)
        WRITE(*, '(5(1x,es13.6,:))') rds%time_Data(:,i,j)
      END DO
    END DO
        
  END SUBROUTINE RadDiag_Stats_Inspect
  

!--------------------------------------------------------------------------------
!:sdoc+:
!
! NAME:
!       RadDiag_Stats_DefineVersion
!
! PURPOSE:
!       Subroutine to return the module version information.
!
! CALLING SEQUENCE:
!       CALL RadDiag_Stats_DefineVersion( Id )
!
! OUTPUTS:
!       Id:            Character string containing the version Id information
!                      for the module.
!                      UNITS:      N/A
!                      TYPE:       CHARACTER(*)
!                      DIMENSION:  Scalar
!                      ATTRIBUTES: INTENT(OUT)
!
!:sdoc-:
!--------------------------------------------------------------------------------

  SUBROUTINE RadDiag_Stats_DefineVersion( Id )
    CHARACTER(*), INTENT(OUT) :: Id
    Id = MODULE_VERSION_ID
  END SUBROUTINE RadDiag_Stats_DefineVersion

END MODULE RadDiag_Stats_Define
