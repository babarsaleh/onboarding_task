# Project Setup Instructions

Follow these steps to set up and run the project.

### 1. Start the Server

To start the Phoenix server, run the following command:

```sh
mix phx.server
```

### 2. Setup ngrok

```sh
ngrok http 4000
```

### 3. Update verify token and access token in respective files
1- Verify token in webhook_controller.ex file
2- Access token in facebook.ex file

### 4. Run Test Cases

```sh
mix test
```

