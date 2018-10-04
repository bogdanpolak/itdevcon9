object DataModMain: TDataModMain
  OldCreateOrder = False
  Height = 150
  Width = 215
  object mtabContacts: TFDMemTable
    FieldDefs = <>
    IndexDefs = <>
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    StoreDefs = True
    Left = 39
    Top = 22
    object mtabContactsImport: TBooleanField
      FieldName = 'Import'
    end
    object mtabContactsEmail: TWideStringField
      FieldName = 'Email'
      Size = 50
    end
    object mtabContactsFirstName: TWideStringField
      FieldName = 'FirstName'
      Size = 100
    end
    object mtabContactsLastName: TWideStringField
      FieldName = 'LastName'
      Size = 100
    end
    object mtabContactsCompany: TWideStringField
      FieldName = 'Company'
      Size = 100
    end
    object mtabContactsDuplicated: TBooleanField
      FieldName = 'Duplicated'
    end
    object mtabContactsConflicts: TBooleanField
      FieldName = 'Conflicts'
    end
    object mtabContactsCurFirstName: TWideStringField
      FieldName = 'CurFirstName'
      Size = 100
    end
    object mtabContactsCurLastName: TWideStringField
      FieldName = 'CurLastName'
      Size = 100
    end
    object mtabContactsCurCompany: TWideStringField
      FieldName = 'CurCompany'
      Size = 100
    end
  end
end
