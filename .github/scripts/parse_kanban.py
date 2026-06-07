import re
from pathlib import Path
from typing import Optional, TypedDict

# --- Type Definitions ---

class RawCard(TypedDict):
    text: str
    done: bool

class Card(TypedDict):
    text: str
    tags: list[str]
    date: Optional[str]
    done: bool

class Column(TypedDict):
    title: str
    limit: Optional[str]
    raw_cards: list[RawCard]
    cards: list[Card]

# --- Core Logic ---

def parse_kanban(file_path: str) -> list[Column]:
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
        
        # Match Columns & Extract Limits
        if stripped_line.startswith('## '):
            if current_column and current_card:
                current_column["raw_cards"].append(current_card)
                current_card = None
                
            raw_title: str = stripped_line.replace('## ', '').strip()
            limit_match: Optional[re.Match] = re.search(r'\s*\((\d+)\)$', raw_title)
            
            limit: Optional[str] = None
            if limit_match:
                limit = limit_match.group(1)
                title: str = raw_title[:limit_match.start()].strip()
            else:
                title = raw_title
                
            current_column = {"title": title, "limit": limit, "raw_cards": [], "cards": []}
            columns.append(current_column)
            
        # Match the start of a new card
        elif stripped_line.startswith('- ['):
            if current_column and current_card:
                current_column["raw_cards"].append(current_card)
            
            is_done: bool = stripped_line.startswith('- [x]')
            current_card = {
                "text": stripped_line[6:].strip() + "\n",
                "done": is_done
            }
            
        # Accumulate multi-line content for the active card
        elif current_card is not None and stripped_line != "":
            current_card["text"] += line.lstrip('\t ') + "\n"

    # Save the very last card
    if current_column and current_card:
        current_column["raw_cards"].append(current_card)
            
    # Process the accumulated raw cards to extract metadata and clean up text
    for col in columns:
        for raw in col["raw_cards"]:
            text: str = raw["text"]
            
            # Extract tags (e.g. #bug)
            tags: list[str] = re.findall(r'#\w+', text)
            for tag in tags:
                text = text.replace(tag, '')
                
            # Extract date format @{YYYY-MM-DD}
            date_match: Optional[re.Match] = re.search(r'@\{(\d{4}-\d{2}-\d{2})\}', text)
            due_date: Optional[str] = date_match.group(1) if date_match else None
            if date_match:
                text = text.replace(date_match.group(0), '')
            
            # Content Formatting
            text = text.strip() 
            
            formatted_lines: list[str] = []
            for line in text.split('\n'):
                if line.startswith('# '):
                    formatted_lines.append(f'<div class="card-title">{line[2:].strip()}</div>')
                else:
                    formatted_lines.append(line)
            
            text = '\n'.join(formatted_lines).strip()
            text = re.sub(r'\n{3,}', '\n\n', text)
            
            col["cards"].append({
                "text": text,
                "tags": tags,
                "date": due_date,
                "done": raw["done"]
            })
            
        col["cards"].sort(key=lambda c: (c["date"] is None, c["date"] or ""))
            
    return columns


def generate_html(columns: list[Column]) -> None:
    html_template: str = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Project Overview Dashboard</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0e1117; color: #c9d1d9; margin: 0; padding: 20px; }
            h1 { text-align: center; color: #f0f6fc; margin-bottom: 30px; }
            .board { display: flex; justify-content: center; gap: 20px; overflow-x: auto; align-items: flex-start; padding-bottom: 20px; }
            .column { background: #161b22; border: 1px solid #30363d; border-radius: 8px; width: 320px; flex-shrink: 0; padding: 15px; }
            
            .column-header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #30363d; padding-bottom: 10px; margin-bottom: 15px; }
            .column-header h2 { font-size: 1.1rem; color: #58a6ff; margin: 0; }
            .column-badge { background: #30363d; color: #8b949e; padding: 2px 8px; border-radius: 12px; font-size: 0.8rem; font-weight: bold; }
            
            .card { background: #21262d; border: 1px solid #30363d; border-radius: 6px; padding: 12px; margin-bottom: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.2); }
            .card.done { opacity: 0.6; border-left: 4px solid #2ea44f; }
            
            .card-title { font-size: 1.15rem; font-weight: bold; color: #f0f6fc; margin-bottom: 6px; }
            .card-text { font-size: 0.95rem; line-height: 1.4; white-space: pre-line; margin-bottom: 8px; }
            
            .meta-container { display: flex; justify-content: space-between; align-items: center; margin-top: 8px; flex-wrap: wrap; gap: 8px; }
            .tag-container { display: flex; flex-wrap: wrap; gap: 4px; }
            .tag { font-size: 0.75rem; padding: 2px 8px; border-radius: 12px; font-weight: bold; background: #30363d; color: #8b949e; }
            
            .tag-bug { background: rgba(101, 0, 0, 1); color: rgba(255, 120, 120, 1); }
            .tag-feature { background: rgba(0, 85, 255, 0.65); color: rgba(116, 172, 255, 1); }
            .tag-mobile { background: rgba(48, 0, 115, 0.88); color: rgba(221, 115, 235, 1); }
            .tag-rework, .tag-optimization { background: #3fb95033; color: #3fb950; }
            
            .date-badge { font-size: 0.75rem; color: #8b949e; display: flex; align-items: center; gap: 4px; }
        </style>
    </head>
    <body>
        <h1>Project Roadmap Dashboard</h1>
        <div class="board">
    """
    
    for col in columns:
        card_count: int = len(col["cards"])
        count_display: str = f"{card_count} / {col['limit']}" if col['limit'] else str(card_count)
        
        html_template += f"""
        <div class="column">
            <div class="column-header">
                <h2>{col["title"]}</h2>
                <span class="column-badge">{count_display}</span>
            </div>
        """
        
        for card in col["cards"]:
            done_class: str = "done" if card["done"] else ""
            html_template += f'<div class="card {done_class}">'
            
            if card["text"]:
                html_template += f'<div class="card-text">{card["text"]}</div>'
            
            html_template += '<div class="meta-container">'
            if card["tags"]:
                html_template += '<div class="tag-container">'
                for tag in card["tags"]:
                    clean_tag: str = tag.replace('#', '')
                    html_template += f'<span class="tag tag-{clean_tag}">{tag}</span>'
                html_template += '</div>'
                
            if card["date"]:
                html_template += f'<div class="date-badge">📅 {card["date"]}</div>'
                
            html_template += '</div></div>'
            
        html_template += '</div>'
        
    html_template += "</div></body></html>"
    
    repo_root: Path = Path(__file__).parent.parent.parent
    (repo_root / 'index.html').write_text(html_template, encoding='utf-8')


if __name__ == "__main__":
    board_data: list[Column] = parse_kanban('TODO_KANBAN.md') 
    generate_html(board_data)