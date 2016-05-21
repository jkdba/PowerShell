function New-ToastNotification
{
    [CmdletBinding()]
    param
    (
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [String] $AppName,
        [Parameter(
            Position = 1,
            Mandatory = $true
        )]
        [String] $Title,
        [Parameter(
            Position = 2,
            Mandatory = $true
        )]
        [String] $Body
    )
    process
    {
        $null = [System.Reflection.Assembly]::LoadFile("C:\bin\assembly\NotificationsExtensions.Win10.NETCore.dll")
        $null = [Windows.Data.Xml.Dom.XmlDocument,Windows.Web,ContentType=WindowsRunTime]
        $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        $null = [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime]
        $ToastContent = New-Object NotificationsExtensions.Toasts.ToastContent
        $ToastContent.Launch = $AppName
        $ToastText = New-Object NotificationsExtensions.Toasts.ToastText
        $ToastText.Text = $Title
        $ToastTextBody = New-Object NotificationsExtensions.Toasts.ToastText
        $ToastTextBody.Text = $Body
        $AppLogo = New-Object NotificationsExtensions.Toasts.ToastAppLogo
        $AppLogo.Crop = [NotificationsExtensions.Toasts.ToastImageCrop]::Circle
        $AppLogo.Source = New-Object NotificationsExtensions.Toasts.ToastImageSource("C:\sys\ui\3.png")
        $ToastVisual = New-Object NotificationsExtensions.Toasts.ToastVisual
        $ToastVisual.AppLogoOverride = $AppLogo
        $ToastVisual.TitleText = $ToastText
        $ToastVisual.BodyTextLine1 = $ToastTextBody
        $ToastContent.Visual = $ToastVisual
        $ToastContent.Duration = "long"
        $ToastContent.ActivationType = "Background"
        $Content = $ToastContent.GetContent()
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($Content)
        $toast=[Windows.UI.Notifications.ToastNotification]::new($xml)
        $toast.ExpirationTime = (Get-Date).AddDays(1000)
        $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppName)
        $notifier.Show($toast)

        ##Old##
        # $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText04)
        # $ToastXml = [xml] $template.GetXml()
        # $ToastElements = $ToastXml.GetElementsByTagName("text")
        # # $null = for($i=0;$i -lt $ToastElements.Id.Count; $i++){$ToastElements[$i].AppendChild($ToastXml.CreateTextNode("Line $i"));}
        # $null=$ToastElements[0].AppendChild($ToastXml.CreateTextNode($NotificationTitle))
        # $null=$ToastElements[1].AppendChild($ToastXml.CreateTextNode($NotificationBody))
        # # $null=$ToastElements[2].AppendChild($ToastXml.CreateTextNode($NotificationBody))
        # [string] $imagePath = "C:\sys\ui\3.png"
        # $imageElements = $ToastXml.GetElementsByTagName("image");
        # # $x=$imageElements[0].Attributes.GetNamedItem("src")
        # # $x.'#text' = $imagePath
        # $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        # $xml.LoadXml($ToastXml.OuterXml)
        # $toast=[Windows.UI.Notifications.ToastNotification]::new($xml)
        # $toast.Tag = $NotificationTitle
        # $toast.Group = $NotificationTitle
        # $toast.ExpirationTime = (Get-Date).AddHours(2)
        # $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($NotificationTitle)
        # $notifier.Show($toast)
    }
}


