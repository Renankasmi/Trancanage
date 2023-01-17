object Form1: TForm1
  Left = 2
  Top = -5
  AutoScroll = False
  Caption = 'Treuil'
  ClientHeight = 696
  ClientWidth = 1015
  Color = clBtnFace
  Constraints.MinHeight = 682
  Constraints.MinWidth = 1004
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  Scaled = False
  Visible = True
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lb_k1: TLabel
    Left = 536
    Top = 504
    Width = 26
    Height = 13
    Caption = 'lb_k1'
    Visible = False
  end
  object lb_k2: TLabel
    Left = 536
    Top = 536
    Width = 26
    Height = 13
    Caption = 'lb_k2'
    Visible = False
  end
  object lb_k3: TLabel
    Left = 536
    Top = 576
    Width = 26
    Height = 13
    Caption = 'lb_k3'
    Visible = False
  end
  object lb_k4: TLabel
    Left = 536
    Top = 616
    Width = 26
    Height = 13
    Caption = 'lb_k4'
    Visible = False
  end
  object Label1: TLabel
    Left = 16
    Top = 496
    Width = 32
    Height = 13
    Caption = 'Label1'
    Visible = False
  end
  object Label2: TLabel
    Left = 16
    Top = 536
    Width = 32
    Height = 13
    Caption = 'Label2'
    Visible = False
  end
  object Label3: TLabel
    Left = 16
    Top = 576
    Width = 32
    Height = 13
    Caption = 'Label3'
    Visible = False
  end
  object Label4: TLabel
    Left = 16
    Top = 608
    Width = 32
    Height = 13
    Caption = 'Label4'
    Visible = False
  end
  object lb_reg1: TLabel
    Left = 664
    Top = 504
    Width = 25
    Height = 13
    Caption = 'Set 1'
    Visible = False
  end
  object lb_reg2: TLabel
    Left = 768
    Top = 504
    Width = 25
    Height = 13
    Caption = 'Set 2'
    Visible = False
  end
  object lb_reg3: TLabel
    Left = 872
    Top = 504
    Width = 25
    Height = 13
    Caption = 'Set 3'
    Visible = False
  end
  object StringGrid1: TStringGrid
    Tag = 40
    Left = 40
    Top = 64
    Width = 449
    Height = 97
    DefaultColWidth = 80
    FixedCols = 0
    RowCount = 2
    FixedRows = 0
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    ScrollBars = ssNone
    TabOrder = 0
    Visible = False
  end
  object TabControl1: TTabControl
    Left = 656
    Top = 56
    Width = 321
    Height = 121
    TabOrder = 1
    Tabs.Strings = (
      'Installation'
      'Asservissement'
      'div1'
      'div2'
      'div3')
    TabIndex = 0
    OnChange = TabControl1Change
    object connect: TButton
      Left = 8
      Top = 32
      Width = 75
      Height = 25
      Caption = '&Connect'
      TabOrder = 0
      OnClick = connectClick
    end
    object cb_port: TComboBox
      Left = 96
      Top = 32
      Width = 73
      Height = 21
      DropDownCount = 10
      ItemHeight = 13
      ItemIndex = 3
      TabOrder = 1
      Text = 'COM4'
      Items.Strings = (
        'COM1'
        'COM2'
        'COM3'
        'COM4'
        'COM5'
        'COM6'
        'COM7'
        'COM8'
        'COM9')
    end
    object rg_sensor: TRadioGroup
      Left = 224
      Top = 24
      Width = 89
      Height = 65
      Caption = 'capteurs IMU'
      ItemIndex = 0
      Items.Strings = (
        'acc'#233'leros'
        'gyros')
      TabOrder = 2
      Visible = False
    end
    object btn_alignement: TButton
      Left = 160
      Top = 88
      Width = 65
      Height = 25
      Caption = 'alignement'
      TabOrder = 3
      Visible = False
    end
    object btn_store_offset: TButton
      Left = 88
      Top = 88
      Width = 65
      Height = 25
      Caption = 'store_offset'
      TabOrder = 4
      Visible = False
      OnClick = btn_store_offsetClick
    end
    object btn_test_armature: TButton
      Left = 112
      Top = 56
      Width = 89
      Height = 25
      Caption = 'test_armature'
      TabOrder = 5
      Visible = False
    end
    object cb_reverse: TCheckBox
      Left = 240
      Top = 96
      Width = 65
      Height = 17
      Caption = 'reverse'
      TabOrder = 6
      Visible = False
      OnClick = cb_reverseClick
    end
  end
  object V1: TProgressBar
    Left = 64
    Top = 168
    Width = 25
    Height = 297
    Min = 0
    Max = 2048
    Orientation = pbVertical
    Position = 1024
    Smooth = True
    TabOrder = 2
    Visible = False
  end
  object V2: TProgressBar
    Left = 136
    Top = 168
    Width = 25
    Height = 297
    Min = 0
    Max = 2048
    Orientation = pbVertical
    Position = 1024
    Smooth = True
    TabOrder = 3
    Visible = False
  end
  object V3: TProgressBar
    Left = 216
    Top = 168
    Width = 25
    Height = 297
    Min = 0
    Max = 2048
    Orientation = pbVertical
    Position = 1024
    Smooth = True
    TabOrder = 4
    Visible = False
  end
  object V4: TProgressBar
    Left = 288
    Top = 168
    Width = 25
    Height = 297
    Min = 0
    Max = 2048
    Orientation = pbVertical
    Position = 1024
    Smooth = True
    TabOrder = 5
    Visible = False
  end
  object V5: TProgressBar
    Left = 360
    Top = 168
    Width = 25
    Height = 297
    Min = 0
    Max = 2048
    Orientation = pbVertical
    Position = 1024
    Smooth = True
    TabOrder = 6
    Visible = False
  end
  object V6: TProgressBar
    Left = 440
    Top = 168
    Width = 25
    Height = 297
    Min = 0
    Max = 2048
    Orientation = pbVertical
    Position = 1024
    Smooth = True
    TabOrder = 7
    Visible = False
  end
  object V7: TProgressBar
    Left = 520
    Top = 168
    Width = 25
    Height = 297
    Min = 0
    Max = 2048
    Orientation = pbVertical
    Position = 1024
    Smooth = True
    TabOrder = 8
    Visible = False
  end
  object V8: TProgressBar
    Left = 600
    Top = 168
    Width = 25
    Height = 297
    Min = 0
    Max = 2048
    Orientation = pbVertical
    Position = 1024
    Smooth = True
    TabOrder = 9
    Visible = False
  end
  object prog_eep: TButton
    Left = 664
    Top = 128
    Width = 75
    Height = 25
    Caption = 'Prog EEPROM'
    TabOrder = 10
    OnClick = prog_eepClick
  end
  object Memo1: TMemo
    Left = 776
    Top = 184
    Width = 185
    Height = 289
    TabOrder = 11
  end
  object tb_k1: TTrackBar
    Left = 72
    Top = 496
    Width = 457
    Height = 25
    Max = 100
    Orientation = trHorizontal
    Frequency = 10
    Position = 0
    SelEnd = 0
    SelStart = 0
    TabOrder = 12
    ThumbLength = 15
    TickMarks = tmBottomRight
    TickStyle = tsAuto
    Visible = False
    OnChange = tb_k1Change
  end
  object tb_k2: TTrackBar
    Left = 72
    Top = 536
    Width = 457
    Height = 25
    Max = 100
    Orientation = trHorizontal
    Frequency = 10
    Position = 0
    SelEnd = 0
    SelStart = 0
    TabOrder = 13
    ThumbLength = 15
    TickMarks = tmBottomRight
    TickStyle = tsAuto
    Visible = False
    OnChange = tb_k2Change
  end
  object tb_k3: TTrackBar
    Left = 72
    Top = 576
    Width = 457
    Height = 25
    Max = 100
    Orientation = trHorizontal
    Frequency = 10
    Position = 0
    SelEnd = 0
    SelStart = 0
    TabOrder = 14
    ThumbLength = 15
    TickMarks = tmBottomRight
    TickStyle = tsAuto
    Visible = False
    OnChange = tb_k3Change
  end
  object tb_k4: TTrackBar
    Left = 72
    Top = 608
    Width = 457
    Height = 25
    Max = 100
    Orientation = trHorizontal
    Frequency = 10
    Position = 0
    SelEnd = 0
    SelStart = 0
    TabOrder = 15
    ThumbLength = 15
    TickMarks = tmBottomRight
    TickStyle = tsAuto
    Visible = False
    OnChange = tb_k4Change
  end
  object cb_v1: TComboBox
    Left = 40
    Top = 120
    Width = 57
    Height = 21
    ItemHeight = 13
    TabOrder = 16
    Text = 'Rien'
    Visible = False
    Items.Strings = (
      'Rien'
      'Roll'
      'Tilt'
      'M_tilt'
      'M_roll'
      'M_yaw')
  end
  object cb_v2: TComboBox
    Left = 120
    Top = 120
    Width = 57
    Height = 21
    ItemHeight = 13
    TabOrder = 17
    Text = 'Rien'
    Visible = False
    Items.Strings = (
      'Rien'
      'Roll'
      'Tilt'
      'M_tilt'
      'M_roll'
      'M_yaw')
  end
  object cb_v3: TComboBox
    Left = 200
    Top = 120
    Width = 57
    Height = 21
    ItemHeight = 13
    TabOrder = 18
    Text = 'Rien'
    Visible = False
    Items.Strings = (
      'Rien'
      'Roll'
      'Tilt'
      'M_tilt'
      'M_roll'
      'M_yaw')
  end
  object cb_v4: TComboBox
    Left = 280
    Top = 120
    Width = 57
    Height = 21
    ItemHeight = 13
    TabOrder = 19
    Text = 'Rien'
    Visible = False
    Items.Strings = (
      'Rien'
      'Roll'
      'Tilt'
      'M_tilt'
      'M_roll'
      'M_yaw')
  end
  object cb_v5: TComboBox
    Left = 360
    Top = 120
    Width = 57
    Height = 21
    ItemHeight = 13
    TabOrder = 20
    Text = 'Rien'
    Visible = False
    Items.Strings = (
      'Rien'
      'Roll'
      'Tilt'
      'M_tilt'
      'M_roll'
      'M_yaw')
  end
  object cb_v6: TComboBox
    Left = 432
    Top = 120
    Width = 57
    Height = 21
    ItemHeight = 13
    TabOrder = 21
    Text = 'Rien'
    Visible = False
    Items.Strings = (
      'Rien'
      'Roll'
      'Tilt'
      'M_tilt'
      'M_roll'
      'M_yaw')
  end
  object cb_v7: TComboBox
    Left = 504
    Top = 120
    Width = 57
    Height = 21
    ItemHeight = 13
    TabOrder = 22
    Text = 'Rien'
    Visible = False
    Items.Strings = (
      'Rien'
      'Roll'
      'Tilt'
      'M_tilt'
      'M_roll'
      'M_yaw')
  end
  object cb_v8: TComboBox
    Left = 584
    Top = 120
    Width = 57
    Height = 21
    ItemHeight = 13
    TabOrder = 23
    Text = 'Rien'
    Visible = False
    Items.Strings = (
      'Rien'
      'Roll'
      'Tilt'
      'M_tilt'
      'M_roll'
      'M_yaw')
  end
  object cb_reg1: TComboBox
    Left = 664
    Top = 520
    Width = 89
    Height = 21
    ItemHeight = 13
    ItemIndex = 0
    TabOrder = 24
    Text = 'Rien'
    Visible = False
    Items.Strings = (
      'Rien'
      'Kp_roll'
      'Ki_roll'
      'Kd_roll'
      'Kp_tilt'
      'Ki_tilt'
      'Kd_tilt')
  end
  object cb_reg2: TComboBox
    Left = 768
    Top = 520
    Width = 89
    Height = 21
    ItemHeight = 13
    ItemIndex = 0
    TabOrder = 25
    Text = 'Rien'
    Visible = False
    Items.Strings = (
      'Rien'
      'Kp_roll'
      'Ki_roll'
      'Kd_roll'
      'Kp_tilt'
      'Ki_tilt'
      'Kd_tilt')
  end
  object cb_reg3: TComboBox
    Left = 872
    Top = 520
    Width = 89
    Height = 21
    ItemHeight = 13
    ItemIndex = 0
    TabOrder = 26
    Text = 'Rien'
    Visible = False
    Items.Strings = (
      'Rien'
      'Kp_roll'
      'Ki_roll'
      'Kd_roll'
      'Kp_tilt'
      'Ki_tilt'
      'Kd_tilt')
  end
  object rg_roll: TRadioGroup
    Left = 672
    Top = 576
    Width = 137
    Height = 57
    Caption = 'pilotage roll'
    ItemIndex = 0
    Items.Strings = (
      'position'
      'vitesse')
    TabOrder = 27
    Visible = False
  end
  object rg_tilt: TRadioGroup
    Left = 824
    Top = 576
    Width = 129
    Height = 57
    Caption = 'pilotage tilt'
    ItemIndex = 1
    Items.Strings = (
      'position'
      'vitesse')
    TabOrder = 28
    Visible = False
  end
  object max_tk1: TSpinEdit
    Left = 592
    Top = 496
    Width = 49
    Height = 22
    Hint = 'valeur maxi'
    Increment = 10
    MaxValue = 1000
    MinValue = 0
    ParentShowHint = False
    ShowHint = False
    TabOrder = 29
    Value = 10
    Visible = False
    OnChange = max_tk1Change
  end
  object max_tk2: TSpinEdit
    Left = 592
    Top = 536
    Width = 49
    Height = 22
    Increment = 10
    MaxValue = 1000
    MinValue = 0
    TabOrder = 30
    Value = 10
    Visible = False
    OnChange = max_tk2Change
  end
  object max_tk3: TSpinEdit
    Left = 592
    Top = 576
    Width = 49
    Height = 22
    Increment = 10
    MaxValue = 1000
    MinValue = 0
    TabOrder = 31
    Value = 10
    Visible = False
    OnChange = max_tk3Change
  end
  object max_tk4: TSpinEdit
    Left = 592
    Top = 608
    Width = 57
    Height = 22
    Increment = 1000
    MaxValue = 9000
    MinValue = 0
    TabOrder = 32
    Value = 10
    Visible = False
  end
  object btn_limL: TButton
    Left = 800
    Top = 544
    Width = 75
    Height = 25
    Caption = 'Limite'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 33
    Visible = False
  end
  object btn_raz_limites: TButton
    Left = 880
    Top = 544
    Width = 75
    Height = 25
    Caption = 'Raz limites'
    TabOrder = 34
    Visible = False
  end
  object btn_zero_as: TButton
    Left = 744
    Top = 544
    Width = 49
    Height = 25
    Caption = 'Z'#233'ro'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 35
    Visible = False
  end
  object Button1: TButton
    Left = 680
    Top = 224
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 36
    Visible = False
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 688
    Top = 264
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 37
    Visible = False
    OnClick = Button2Click
  end
  object btn_calibr_acc: TButton
    Left = 664
    Top = 544
    Width = 75
    Height = 25
    Caption = 'calibr_acc'
    TabOrder = 38
    Visible = False
  end
  object Timer_loop: TTimer
    Enabled = False
    Interval = 100
    OnTimer = Timer_loopTimer
    Left = 696
    Top = 392
  end
  object Timer_start: TTimer
    Enabled = False
    Interval = 100
    OnTimer = Timer_startTimer
    Left = 696
    Top = 448
  end
  object OpenDialog1: TOpenDialog
    Left = 696
    Top = 360
  end
  object SaveDialog1: TSaveDialog
    Left = 696
    Top = 320
  end
  object Timer_ic: TTimer
    Enabled = False
    OnTimer = Timer_icTimer
    Left = 648
    Top = 392
  end
end
