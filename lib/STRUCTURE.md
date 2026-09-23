# My AI Workshop — Feature-Sliced Design

```
lib/
├── main.dart                      # Flutter entry (Firebase + runApp)
├── firebase_options.dart          # .env override + built-in project
├── app/                           # router, theme, firebase bootstrap
├── pages/                         # Home, Upload, one screen per tool
├── features/                      # tool domain logic (ui stays in pages)
├── entities/                      # WorkshopJob, UploadRecord
├── services/                      # firestore_service, auth_service
└── shared/
    ├── api/                       # /api client
    ├── config/                    # breakpoints, catalog, app config
    ├── layouts/                   # responsive shell
    ├── widgets/
    └── utils/
```

Import direction: `pages → features → entities → shared`.
`app` and `services` wire the layers together.
