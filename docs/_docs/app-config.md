---
title: App Configuration
---

You can set application-wide configurations in the `config/application.rb` file. You can configure global things like project_name, extra_autoload_paths, function timeout, memory size, etc. Example:

`config/application.rb`:

```ruby
Jets.application.configure do
  config.project_name = "demo"
  # config.env_extra = 2
  # config.extra_autoload_paths = []
  # config.global_iam_role = # TODO: implement this

  config.function.timeout = 10
  # config.function.role = "arn:aws:iam::#{ENV['AWS_ACCOUNT_ID']}:role/service-role/pre-created"
  # config.function.memory_size= 3008
  # config.function.cors = true
  config.function.environment = {
    global_app_key1: "global_app_value1",
    global_app_key2: "global_app_value2",
  }

  # More examples:
  # config.function.dead_letter_queue = { target_arn: "arn" }
  # config.function.vpc_config = {
  #   security_group_ids: [ "sg-1", "sg-2" ],
  #   subnet_ids: [ "subnet-1", "subnet-2" ]
  # }
  # The config.function settings to the CloudFormation Lambda Function properties.
  # http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-function.html
  # Underscored format can be used for keys to make it look more ruby-ish.
end
```

<a id="prev" class="btn btn-basic" href="{% link _docs/database-activerecord.md %}">Back</a>
<a id="next" class="btn btn-primary" href="{% link _docs/function-properties.md %}">Next Step</a>
<p class="keyboard-tip">Pro tip: Use the <- and -> arrow keys to move back and forward.</p>