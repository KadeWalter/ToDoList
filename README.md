# To Do List (Branch Take Home Project)
### Author: Kade Walter

## AI Usage
I leveraged AI (claude-code) to assist me in the development of this project. I used AI in a way that I would in a production engineering setting. I manually verified that all changes from Claude made sense to add and worked properly. Using AI as a tool in this way sped up development time.

Claude helped me in setting up boilerplate code like the Core Data stack, bridging the network layer and local storage layers with the task repository, and writing the unit test suite. Additionally, Claude helped verify code consistency across the app.

I had Claude do a full code review after development to provide suggestions for improvement. After reading through Claude's review, I did my own manual review of the project.

## Project Decisions
### Swift 6
This app is built with the Swift 6 language version. The decision here was to ensure full Swift Concurrency support. I adjusted 2 build settings when updating this: Swift Language Version -> Swift 6 and Strict Concurrency Checking -> Complete.

### UI
There are several decisions I made in the functionality of this project with unclear requirements. In a production setting, I would verify these decisions with product and design. An example of these decisions is sorting the tasks alphabetically by title, regardless of the completion state. As a result, completed tasks and uncompleted tasks are mixed together in the list.

Another decision I made was to use a List instead of a ScrollView. Due to the simplicity of the view and the need for swipe actions, a List made more sense here. However, another consideration was using a ScrollView with a LazyVStack for more flexibility and control. In iOS 27, Apple is adding a new modifier to ScrollView, called .swipeContainer(), that will allow for swipe actions to be used inside of a ScrollView.

When fetching from the remote list of tasks, after toggling the completed state of a task and then re-fetching, the user will not see the tasks completed reset to the API's completed state. This was a decision that I felt made the most sense. So any tasks stored on the device will not be updated on refetch, but the app will save new tasks the API returns.

### MVVM Architecture
The view model used for TaskItemView only stores a value and invokes a callback. Because of this, TaskItemViewModel is not really needed, and the update for toggling a task's state could be done a layer higher in the ToDoListViewModel. However, I kept the view model for this view to stay consistent with the MVVM pattern. I saw this as a trade-off of ease vs consistency.

### Core Data
I decided to use Core Data as the local persistent storage layer. I chose Core Data because I wanted to use native persistent storage for iOS apps. I chose Core Data over SwiftData due to my personal familiarity with Core Data. I have not used SwiftData yet, so I am not as knowledgeable about its persistent solution at the moment.

I have several layers to my Core Data and Networking stack. There is a TaskRepository that facilitates the coordination of TaskItems between the Core Data layer and the Networking layer. Additionally, there is a TaskModel struct that is used in feature code, rather than passing the TaskItem managed object into view code. Updates from the view on task items (checking the checkbox to mark a task as completed) update the TaskModel, which then updates the persistent record in the TaskStore.update() function.

The repository is the only dependency passed into the view model, and the view has no knowledge of the TaskRepository. This allows the view model to state what it wants, and the repository is in charge of how it gets the data. The TaskRepository accesses the TaskStore, which loads data from Core Data, and accesses the TaskDataSource to fetch tasks from the remote API. 

## App Expansions to Consider
### Feature Improvements
There are several feature improvements that can be considered to expand the app:
- **Add date logic**

    Tracking dates such as due date, created date, and completed date can be used as properties on the TaskItem for better sorting, and setting times for when a user wants a task to be completed by.

- **Completed tasks area**

    Adding a different tab or a new section for completed tasks could allow for separating completed tasks from uncompleted tasks. This would make the task list easier to read for users, allowing them to better understand which tasks still need to be done at a quick glance.

- **Filtering by user_id**
    
    When fetching tasks from the remote API, there is a `user_id` property on each task. I am not utilizing this user id, and just showing all tasks returned in the app. However, the app could be expanded to filter by user id so a user only sees their tasks.

### Modularization
I determined modularization to be out of scope for this project. However, to expand to a more scalable architecture, I would move the Core Data and Networking layers to their own modules for a better separation of concerns.
