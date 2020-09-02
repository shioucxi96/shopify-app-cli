# frozen_string_literal: true
module Theme
  module Messages
    MESSAGES = {
      theme: {
        checking_themekit: "Verifying Theme Kit",
        create: {
          creating_theme: "Creating theme %s",
          duplicate_theme: "Duplicate theme",
          failed: "Couldn't create the theme",
          help: <<~HELP,
            {{command:%s create theme}}: Creates a theme.
              Usage: {{command:%s create theme}}
              Options:
                {{command:--store=MYSHOPIFYDOMAIN}} Store URL. Must be an existing store with private apps enabled.
                {{command:--password=PASSWORD}} Private app password. App must have Read and Write Theme access.
                {{command:--name=NAME}} Theme name. Any string.
          HELP
          info: {
            created: "{{green:%s}} was created for {{underline:%s}} in {{green:%s}}",
          },
        },
        forms: {
          ask_password: "Password:",
          ask_store: "Store domain:",
          create: {
            ask_title: "Title:",
            private_app: <<~APP,
              To create a new theme, Shopify App CLI needs to connect with a private app installed on your store. Visit {{underline:%s/admin/apps/private}} to create a new API key and password, or retrieve an existing password.
              If you create a new private app, ensure that it has Read and Write Theme access.",
            APP
          },
          errors: "%s can't be blank",
          pull: {
            private_app: <<~APP,
              To fetch your existing themes, Shopify App CLI needs to connect with your store. Visit {{underline:%s/admin/apps/private}} to create a new API key and password, or retrieve any existing password.
              If you create a new private app, ensure that it has Read and Write Theme access.",
            APP
          },
        },
        pull: {
          help: <<~HELP,
            {{command:%s pull}}: Connects an existing theme in your store to Shopify App CLI. Creates a local copy of theme files on Shopify.
              Usage: {{command:%s pull}}
              Options:
                {{command:--store=MYSHOPIFYDOMAIN}} Store URL. Must be an existing store with private apps enabled.
                {{command:--password=PASSWORD}} Private app password. App must have Read and Write Theme access.
                {{command:--themeid=THEMEID}} Theme ID. Must be an existing theme on your store.
          HELP
          pull: "Pulling theme...",
          failed: "Couldn't pull from store",
          pulled: "{{green:%s}} was pulled from {{underline:%s}} to {{green:%s}}",
        },
        serve: {
          help: <<~HELP,
            Sync your current changes, then view the active store in your default browser. Any theme edits will continue to update in real time. Also prints the active store's URL in your terminal.
            Usage: {{command:%s serve}}
          HELP
          serve: "Viewing theme...",
          open_fail: "Couldn't open the theme",
        },
        tasks: {
          ensure_themekit_installed: {
            downloading: "Downloading Theme Kit %s",
            errors: {
              digest_fail: "Unable to verify download",
              releases_fail: "Unable to fetch Theme Kit's list of releases",
              write_fail: "Unable to download Theme Kit",
            },
            successful: "Theme Kit installed successfully",
            verifying: "Verifying download...",
          },
        },
      },
    }.freeze
  end
end
