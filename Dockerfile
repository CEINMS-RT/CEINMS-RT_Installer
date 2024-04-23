FROM mcr.microsoft.com/windows:20H2-amd64

RUN ["powershell New-Item -Path ~/CEINMSFiles/ -ItemType Directory"]
COPY * ~/CEINMSFiles/

CMD ["powershell"]