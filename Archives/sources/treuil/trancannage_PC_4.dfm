object Form1: TForm1
  Left = 0
  Top = 3
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
    Left = 664
    Top = 504
    Width = 329
    Height = 121
    TabOrder = 1
    Tabs.Strings = (
      'Installation'
      'Position'
      'Courant'
      'div2'
      'div3')
    TabIndex = 0
    OnChange = TabControl1Change
    object connect: TButton
      Left = 8
      Top = 24
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
      ItemIndex = 1
      TabOrder = 1
      Text = 'COM2'
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
    object rg_lin: TRadioGroup
      Left = 200
      Top = 24
      Width = 113
      Height = 65
      Caption = 'mouvement'
      ItemIndex = 0
      Items.Strings = (
        'rotation constante'
        'lin'#233'aire')
      TabOrder = 2
      Visible = False
      OnClick = rg_linClick
    end
    object btn_neutre: TButton
      Left = 176
      Top = 88
      Width = 65
      Height = 25
      Caption = 'neutre'
      TabOrder = 3
      Visible = False
      OnClick = btn_neutreClick
    end
    object btn_store_offset: TButton
      Left = 104
      Top = 88
      Width = 65
      Height = 25
      Caption = 'store_offset'
      TabOrder = 4
      Visible = False
      OnClick = btn_store_offsetClick
    end
    object btn_inc_consigne: TButton
      Left = 112
      Top = 56
      Width = 81
      Height = 25
      Caption = '&inc_consigne'
      TabOrder = 5
      Visible = False
      OnClick = btn_inc_consigneClick
    end
    object btn_limite: TButton
      Left = 240
      Top = 88
      Width = 75
      Height = 25
      Caption = 'limite'
      TabOrder = 6
      Visible = False
      OnClick = btn_limiteClick
    end
    object cb_select: TCheckBox
      Left = 8
      Top = 88
      Width = 57
      Height = 17
      Caption = 'select'
      TabOrder = 7
    end
  end
  object prog_eep: TButton
    Left = 680
    Top = 560
    Width = 75
    Height = 25
    Caption = 'Prog EEPROM'
    TabOrder = 2
    OnClick = prog_eepClick
  end
  object Memo1: TMemo
    Left = 776
    Top = 184
    Width = 185
    Height = 289
    TabOrder = 3
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
    TabOrder = 4
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
    TabOrder = 5
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
    TabOrder = 6
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
    TabOrder = 7
    ThumbLength = 15
    TickMarks = tmBottomRight
    TickStyle = tsAuto
    Visible = False
    OnChange = tb_k4Change
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
    TabOrder = 8
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
    TabOrder = 9
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
    TabOrder = 10
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
    TabOrder = 11
    Value = 10
    Visible = False
  end
  object aff_curve1: TButton
    Left = 680
    Top = 224
    Width = 75
    Height = 25
    Caption = 'aff_curve1'
    TabOrder = 12
    Visible = False
    OnClick = aff_curve1Click
  end
  object aff_curve2: TButton
    Left = 688
    Top = 264
    Width = 75
    Height = 25
    Caption = 'aff_curve2'
    TabOrder = 13
    Visible = False
    OnClick = aff_curve2Click
  end
  object cb1: TCheckBox
    Left = 72
    Top = 40
    Width = 41
    Height = 17
    TabOrder = 14
    Visible = False
  end
  object cb2: TCheckBox
    Left = 152
    Top = 40
    Width = 33
    Height = 17
    TabOrder = 15
    Visible = False
  end
  object cb3: TCheckBox
    Left = 224
    Top = 40
    Width = 33
    Height = 17
    TabOrder = 16
    Visible = False
  end
  object cb4: TCheckBox
    Left = 304
    Top = 40
    Width = 33
    Height = 17
    TabOrder = 17
    Visible = False
  end
  object cb5: TCheckBox
    Left = 384
    Top = 40
    Width = 33
    Height = 17
    TabOrder = 18
    Visible = False
  end
  object cb6: TCheckBox
    Left = 464
    Top = 40
    Width = 97
    Height = 17
    TabOrder = 19
    Visible = False
  end
  object cb7: TCheckBox
    Left = 544
    Top = 40
    Width = 97
    Height = 17
    TabOrder = 20
    Visible = False
  end
  object cb8: TCheckBox
    Left = 624
    Top = 40
    Width = 97
    Height = 17
    TabOrder = 21
    Visible = False
  end
  object cb9: TCheckBox
    Left = 704
    Top = 40
    Width = 97
    Height = 17
    TabOrder = 22
    Visible = False
  end
  object cb10: TCheckBox
    Left = 784
    Top = 40
    Width = 97
    Height = 17
    TabOrder = 23
    Visible = False
  end
  object aff_curve3: TButton
    Left = 688
    Top = 192
    Width = 75
    Height = 25
    Caption = 'aff_curve3'
    TabOrder = 24
    Visible = False
    OnClick = aff_curve3Click
  end
  object memo_curve1: TButton
    Left = 608
    Top = 264
    Width = 75
    Height = 25
    Caption = 'memo_curve1'
    TabOrder = 25
    Visible = False
    OnClick = memo_curve1Click
  end
  object memo_curve2: TButton
    Left = 592
    Top = 224
    Width = 75
    Height = 25
    Caption = 'memo_curve2'
    TabOrder = 26
    Visible = False
    OnClick = memo_curve2Click
  end
  object memo_curve3: TButton
    Left = 592
    Top = 192
    Width = 75
    Height = 25
    Caption = 'memo_curve3'
    TabOrder = 27
    Visible = False
    OnClick = memo_curve3Click
  end
  object LOG: TButton
    Left = 680
    Top = 640
    Width = 75
    Height = 25
    Caption = 'LOG'
    TabOrder = 28
    OnClick = LOGClick
  end
  object btn_sel: TButton
    Left = 736
    Top = 592
    Width = 25
    Height = 25
    Caption = 'I/0'
    TabOrder = 29
    OnClick = btn_selClick
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
