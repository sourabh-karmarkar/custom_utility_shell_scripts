#!/bin/bash

# Define the log file name
LOG_FILE="git_pull_all_repos_log.txt"

# Function to check if a directory is a Git repository
is_git_repository() {
  git -C "$1" rev-parse --is-inside-work-tree &> /dev/null
}

# Function to pull from the current branch in a Git repository
pull_from_current_branch() {
  if is_git_repository "$1"; then
    cd "$1" || return
    branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
      echo "Pulling from $branch in $(pwd)" >> "$LOG_FILE"
      git pull >> "$LOG_FILE" 2>&1
      if [ $? -eq 0 ]; then
        echo "Success" >> "$LOG_FILE"
      else
        echo "Error" >> "$LOG_FILE"
      fi
    fi
    cd - > /dev/null
  fi
}

# Main loop to traverse folders and pull from Git repositories
for dir in */; do
  dir="${dir%/}" # Remove trailing slash
  echo "$dir"
done

echo "Git pull process completed. Check $LOG_FILE for details."
