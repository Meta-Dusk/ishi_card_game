import re
from pathlib import Path
from typing import Optional
from dataclasses import dataclass, field

# --- Type Definitions ---

@dataclass
class RawCard:
    text: str
    done: bool

@dataclass
class Card:
    text: str
    tags: list[str]
    date: Optional[str]
    archived_date: Optional[str]
    done: bool

@dataclass
class Column:
    title: str
    limit: Optional[str]
    raw_cards: list[RawCard] = field(default_factory=list)
    cards: list[Card] = field(default_factory=list)

# --- Core Logic ---

def parse_kanban(file_path: str) -> list[Column]:
    print("Parsing kanban...", end=" ")
    repo_root: Path = Path(__file__).parent.parent.parent
    target_file: Path = repo_root / file_path
    
    content: str = target_file.read_text(encoding='utf-8')
    main_content: str = content.split('%%')[0]
    lines: list[str] = main_content.split('\n')
    
    columns: list[Column] = []
    current_column: Optional[Column] = None
    current_card: Optional[RawCard] = None
    
    for line in lines:
        stripped_line: str = line.strip()
        
        # Ignore markdown dividers
        if stripped_line == '***' or stripped_line == '---':
            continue
            
        # Match Columns & Extract Limits
        if stripped_line.startswith('## '):
            if current_column and current_card:
                current_column.raw_cards.append(current_card)
                current_card = None
                
            raw_title: str = stripped_line.replace('## ', '').strip()
            limit_match: Optional[re.Match] = re.search(r'\s*\((\d+)\)$', raw_title)
            
            limit: Optional[str] = None
            if limit_match:
                limit = limit_match.group(1)
                title: str = raw_title[:limit_match.start()].strip()
            else:
                title = raw_title
                
            current_column = Column(title=title, limit=limit)
            columns.append(current_column)
            
        # Match the start of a new card
        elif stripped_line.startswith('- ['):
            if current_column and current_card:
                current_column.raw_cards.append(current_card)
            
            is_done: bool = stripped_line.startswith('- [x]')
            current_card = RawCard(
                text=stripped_line[6:].strip() + "\n",
                done=is_done
            )
            
        # Accumulate multi-line content for the active card
        elif current_card is not None and stripped_line != "":
            current_card.text += line.lstrip('\t ') + "\n"

    # Save the very last card
    if current_column and current_card:
        current_column.raw_cards.append(current_card)
            
    # Process the accumulated raw cards
    for col in columns:
        for raw in col.raw_cards:
            text: str = raw.text
            
            # Extract tags
            tags: list[str] = re.findall(r'#\w+', text)
            for tag in tags:
                text = text.replace(tag, '')
                
            # Extract date format @{YYYY-MM-DD} AND optional archive date | YYYY-MM-DD HH:MM
            date_match: Optional[re.Match] = re.search(r'@\{(\d{4}-\d{2}-\d{2})\}(?:\s*\|\s*(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}))?', text)
            due_date: Optional[str] = date_match.group(1) if date_match else None
            archived_date: Optional[str] = date_match.group(2) if date_match and date_match.group(2) else None
            
            if date_match:
                text = text.replace(date_match.group(0), '')
            
            # Content Formatting
            text = text.strip() 
            
            # Parse inline code blocks (`code`)
            text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
            
            formatted_lines: list[str] = []
            for line in text.split('\n'):
                if line.startswith('# '):
                    formatted_lines.append(f'<div class="card-title">{line[2:].strip()}</div>')
                else:
                    formatted_lines.append(line)
            
            text = '\n'.join(formatted_lines).strip()
            text = re.sub(r'\n{3,}', '\n\n', text)
            
            col.cards.append(Card(
                text=text,
                tags=tags,
                date=due_date,
                archived_date=archived_date,
                done=raw.done
            ))
            
        # Sort regular columns by date. (Archive will be handled separately)
        col.cards.sort(key=lambda c: (c.date is None, c.date or ""))
    
    print("Finished")
    return columns


def generate_html(columns: list[Column]) -> None:
    print("Generating html...", end=" ")
    # Separate the Archive column from the standard Kanban board columns
    regular_columns = [col for col in columns if col.title.lower() != "archive"]
    archive_column = next((col for col in columns if col.title.lower() == "archive"), None)

    html_template: str = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Project Overview Dashboard</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0e1117; color: #c9d1d9; margin: 0; padding: 20px; }
            
            /* Top Navigation Bar */
            .top-bar { display: flex; justify-content: space-between; align-items: center; max-width: 1200px; margin: 0 auto 30px auto; padding: 0 20px; }
            h1 { color: #f0f6fc; margin: 0; }
            .btn-toggle { background: #21262d; color: #c9d1d9; border: 1px solid #30363d; padding: 8px 16px; border-radius: 6px; cursor: pointer; font-weight: bold; transition: background 0.2s; }
            .btn-toggle:hover { background: #30363d; border-color: #8b949e; }
            
            /* Custom Sleek Scrollbar */
            ::-webkit-scrollbar { width: 8px; height: 8px; }
            ::-webkit-scrollbar-track { background: #0e1117; }
            ::-webkit-scrollbar-thumb { background: #30363d; border-radius: 4px; }
            ::-webkit-scrollbar-thumb:hover { background: #484f58; }

            /* Responsive Board Layout */
            .board { display: flex; flex-wrap: wrap; justify-content: center; gap: 20px; align-items: flex-start; padding-bottom: 20px; }
            .column { background: #161b22; border: 1px solid #30363d; border-radius: 8px; width: 100%; max-width: 320px; padding: 15px; box-sizing: border-box; }
            
            .column-header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #30363d; padding-bottom: 10px; margin-bottom: 15px; }
            .column-header h2 { font-size: 1.1rem; color: #58a6ff; margin: 0; }
            .column-badge { background: #30363d; color: #8b949e; padding: 2px 8px; border-radius: 12px; font-size: 0.8rem; font-weight: bold; }
            
            /* Enhanced Card Styling with Hover Effects */
            .card { background: #21262d; border: 1px solid #30363d; border-radius: 6px; padding: 12px; margin-bottom: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.2); transition: transform 0.2s ease, border-color 0.2s ease, box-shadow 0.2s ease; }
            .card:hover { transform: translateY(-2px); border-color: #8b949e; box-shadow: 0 6px 12px rgba(0,0,0,0.3); }
            .card.done { opacity: 0.6; border-left: 4px solid #2ea44f; }
            .card-title { font-size: 1.15rem; font-weight: bold; color: #f0f6fc; margin-bottom: 6px; }
            .card-text { font-size: 0.95rem; line-height: 1.4; white-space: pre-line; margin-bottom: 8px; }
            
            /* Inline Code Styling */
            code { font-family: ui-monospace, SFMono-Regular, Consolas, "Liberation Mono", monospace; font-size: 0.85em; background-color: rgba(110, 118, 129, 0.4); border-radius: 6px; padding: 0.2em 0.4em; color: #f0f6fc; }
            
            .meta-container { display: flex; justify-content: space-between; align-items: center; margin-top: 8px; flex-wrap: wrap; gap: 8px; }
            .tag-container { display: flex; flex-wrap: wrap; gap: 4px; }
            .tag { font-size: 0.75rem; padding: 2px 8px; border-radius: 12px; font-weight: bold; background: #30363d; color: #8b949e; }
            
            /* Dynamic Tag Colors */
            .tag-bug { background: rgba(101, 0, 0, 1); color: rgba(255, 120, 120, 1); }
            .tag-feature { background: rgba(0, 85, 255, 0.65); color: rgba(116, 172, 255, 1); }
            .tag-mobile { background: rgba(48, 0, 115, 0.88); color: rgba(221, 115, 235, 1); }
            .tag-rework, .tag-optimization { background: #3fb95033; color: #3fb950; }
            .tag-documentation { background: rgba(0, 4, 65, 1); color: rgba(74, 125, 255, 1); }
            .tag-github { background: rgba(255, 255, 255, 1); color: rgba(0, 0, 0, 1); }
            
            .date-badge { font-size: 0.75rem; color: #8b949e; display: flex; align-items: center; gap: 4px; }
            
            /* Archive List View Styling */
            .archive-container { display: none; max-width: 1000px; margin: 40px auto 0 auto; padding: 20px; border-top: 1px dashed #30363d; }
            .archive-container h2 { color: #8b949e; text-align: center; margin-bottom: 20px; font-size: 1.1rem; text-transform: uppercase; letter-spacing: 1px; }
            .archive-list { display: flex; flex-direction: column; gap: 10px; }
            .archive-item { background: #161b22; border: 1px solid #30363d; border-radius: 6px; padding: 15px 20px; display: flex; flex-direction: column; gap: 10px; opacity: 0.8; transition: opacity 0.2s, border-color 0.2s; }
            .archive-item:hover { opacity: 1; border-color: #8b949e; }
            .archive-item-top { display: flex; justify-content: space-between; align-items: flex-start; gap: 20px; flex-wrap: wrap; }
            .archive-meta { font-size: 0.85rem; color: #8b949e; display: flex; gap: 15px; align-items: center; }
            
        </style>
    </head>
    <body>
        <div class="top-bar">
            <h1>Project Roadmap Dashboard</h1>
            <button id="archiveBtn" class="btn-toggle" onclick="toggleArchive()">Show Archive</button>
        </div>
        
        <div class="board">
    """
    
    # Render Regular Columns
    for col in regular_columns:
        card_count: int = len(col.cards)
        count_display: str = f"{card_count} / {col.limit}" if col.limit else str(card_count)
        
        html_template += f"""
        <div class="column">
            <div class="column-header">
                <h2>{col.title}</h2>
                <span class="column-badge">{count_display}</span>
            </div>
        """
        for card in col.cards:
            done_class: str = "done" if card.done else ""
            html_template += f'<div class="card {done_class}">'
            
            if card.text:
                html_template += f'<div class="card-text">{card.text}</div>'
            
            html_template += '<div class="meta-container">'
            if card.tags:
                html_template += '<div class="tag-container">'
                for tag in card.tags:
                    clean_tag: str = tag.replace('#', '')
                    html_template += f'<span class="tag tag-{clean_tag}">{tag}</span>'
                html_template += '</div>'
                
            if card.date:
                html_template += f'<div class="date-badge">📅 {card.date}</div>'
                
            html_template += '</div></div>'
        html_template += '</div>'
    html_template += "</div>" # Close board
    
    # Render Archive Section
    if archive_column and archive_column.cards:
        # Sort archived cards by archived_date descending (newest at the top)
        archive_column.cards.sort(key=lambda c: c.archived_date or "", reverse=True)
        
        html_template += """
        <div id="archiveSection" class="archive-container">
            <h2>Archived Tasks</h2>
            <div class="archive-list">
        """
        for card in archive_column.cards:
            html_template += f"""
                <div class="archive-item">
                    <div class="archive-item-top">
                        <div class="card-text" style="margin: 0;">{card.text}</div>
                        <div class="archive-meta">
            """
            
            if card.tags:
                html_template += '<div class="tag-container">'
                for tag in card.tags:
                    clean_tag: str = tag.replace('#', '')
                    html_template += f'<span class="tag tag-{clean_tag}">{tag}</span>'
                html_template += '</div>'
            
            # Display completion timestamp
            if card.archived_date:
                html_template += f'<span title="Completed On">✅ {card.archived_date}</span>'
                
            html_template += """
                        </div>
                    </div>
                </div>
            """
        html_template += "</div></div>"

    # Inject Toggle Script
    html_template += """
        <script>
            function toggleArchive() {
                const section = document.getElementById('archiveSection');
                const btn = document.getElementById('archiveBtn');
                const display = section.style.display;
                if (!section) return;
                
                if (display === 'none' || display === '') {
                    section.style.display = 'block';
                    btn.innerText = 'Hide Archive';
                } else {
                    section.style.display = 'none';
                    btn.innerText = 'Show Archive';
                }
            }
        </script>
    </body>
    </html>
    """
    
    repo_root: Path = Path(__file__).parent.parent.parent
    (repo_root / 'index.html').write_text(html_template, encoding='utf-8')
    print("Finished")


if __name__ == "__main__":
    print("Parsing and generating Kanban Dashboard...")
    board_data: list[Column] = parse_kanban('TODO_KANBAN.md') 
    generate_html(board_data)
    print("Generated Kanban Dashboard!")