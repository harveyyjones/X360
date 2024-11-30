# X360 AI Schedule Planner


## How to add a new field to the response from the Gemini?

In schedule_task.dart:

- Add field (taskType).
- Add to toJson().
- Add to fromJson factory.

In gemini_service.dart:

- Update prompt to tell Gemini to include taskType.
- Update example JSON format in the prompt.

The caching system will automatically handle the new field because it just serializes the complete ScheduleTask objects.
# X360
